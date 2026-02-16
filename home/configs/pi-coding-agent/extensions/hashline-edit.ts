import {
  DEFAULT_MAX_BYTES,
  DEFAULT_MAX_LINES,
  createReadTool,
  formatSize,
  truncateHead,
  type ExtensionAPI,
} from "@mariozechner/pi-coding-agent";
import type { TruncationResult } from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";
import { createHash } from "node:crypto";
import { constants } from "node:fs";
import { access, readFile, writeFile } from "node:fs/promises";
import { resolve } from "node:path";

const IMAGE_EXT_RE = /\.(png|jpe?g|gif|webp)$/i;

const readSchema = Type.Object({
  path: Type.String({
    description: "Path to the file to read (relative or absolute)",
  }),
  offset: Type.Optional(
    Type.Number({
      description: "Line number to start reading from (1-indexed)",
    }),
  ),
  limit: Type.Optional(
    Type.Number({ description: "Maximum number of lines to read" }),
  ),
});

const editSchema = Type.Object({
  path: Type.String({
    description: "Path to the file to edit (relative or absolute)",
  }),
  edits: Type.Array(
    Type.Union([
      Type.Object(
        {
          set_line: Type.Object({
            anchor: Type.String({
              description:
                "Line reference from read output, format <line>:<hash>",
            }),
            new_text: Type.String({
              description: "Replacement text for the anchored line",
            }),
          }),
        },
        { additionalProperties: false },
      ),
      Type.Object(
        {
          replace_lines: Type.Object({
            start_anchor: Type.String({
              description: "Start line reference, format <line>:<hash>",
            }),
            end_anchor: Type.String({
              description: "End line reference, format <line>:<hash>",
            }),
            new_text: Type.String({
              description: "Replacement text for the anchored range",
            }),
          }),
        },
        { additionalProperties: false },
      ),
      Type.Object(
        {
          insert_after: Type.Object({
            anchor: Type.String({
              description: "Line reference after which text is inserted",
            }),
            text: Type.String({
              description: "Text to insert after the anchored line",
            }),
          }),
        },
        { additionalProperties: false },
      ),
      Type.Object(
        {
          replace: Type.Object({
            old_text: Type.String({
              description: "Exact text to replace. Must be unique in file.",
            }),
            new_text: Type.String({ description: "Replacement text" }),
          }),
        },
        { additionalProperties: false },
      ),
    ]),
    {
      minItems: 1,
      description: "List of hashline edit operations to apply atomically",
    },
  ),
});

type ReadInput = {
  path: string;
  offset?: number;
  limit?: number;
};

type SetLineEdit = {
  set_line: {
    anchor: string;
    new_text: string;
  };
};

type ReplaceLinesEdit = {
  replace_lines: {
    start_anchor: string;
    end_anchor: string;
    new_text: string;
  };
};

type InsertAfterEdit = {
  insert_after: {
    anchor: string;
    text: string;
  };
};

type ReplaceEdit = {
  replace: {
    old_text: string;
    new_text: string;
  };
};

type HashlineEdit =
  | SetLineEdit
  | ReplaceLinesEdit
  | InsertAfterEdit
  | ReplaceEdit;

type EditInput = {
  path: string;
  edits: HashlineEdit[];
};

type EditDiffResult = {
  diff: string;
  firstChangedLine?: number;
};

type ParsedAnchor = {
  line: number;
  hash: string;
};

type AnchoredOperation = {
  type: "set_line" | "replace_lines" | "insert_after";
  startLineIndex: number;
  endLineIndex: number;
  text: string;
};

function normalizeInputPath(path: string): string {
  return path.startsWith("@") ? path.slice(1) : path;
}

function normalizeToLf(text: string): string {
  return text.replace(/\r\n/g, "\n").replace(/\r/g, "\n");
}

function detectLineEnding(content: string): "\n" | "\r\n" {
  const crlfIndex = content.indexOf("\r\n");
  const lfIndex = content.indexOf("\n");

  if (lfIndex === -1 || crlfIndex === -1) {
    return "\n";
  }

  return crlfIndex < lfIndex ? "\r\n" : "\n";
}

function restoreLineEndings(
  content: string,
  lineEnding: "\n" | "\r\n",
): string {
  return lineEnding === "\r\n" ? content.replace(/\n/g, "\r\n") : content;
}

function stripBom(content: string): { bom: string; text: string } {
  if (content.startsWith("\uFEFF")) {
    return { bom: "\uFEFF", text: content.slice(1) };
  }

  return { bom: "", text: content };
}

function computeLineHash(line: string): string {
  const normalized = line.replace(/\r/g, "").replace(/\s+/g, "");
  return createHash("sha1").update(normalized).digest("hex").slice(0, 2);
}

function formatHashline(line: string, lineNumber: number): string {
  return `${lineNumber}:${computeLineHash(line)}|${line}`;
}

function parseAnchor(anchor: string): ParsedAnchor {
  const match = anchor.trim().match(/^(\d+):([0-9a-fA-F]{2,3})$/);
  if (!match) {
    throw new Error(
      `Invalid anchor \"${anchor}\". Expected format <line>:<hash>, for example 42:ab.`,
    );
  }

  const line = Number.parseInt(match[1], 10);
  if (!Number.isFinite(line) || line < 1) {
    throw new Error(`Invalid line number in anchor \"${anchor}\".`);
  }

  return {
    line,
    hash: match[2].toLowerCase(),
  };
}

function validateAnchor(anchor: string, lines: string[], path: string): number {
  const parsed = parseAnchor(anchor);
  const lineIndex = parsed.line - 1;

  if (lineIndex < 0 || lineIndex >= lines.length) {
    throw new Error(
      `Anchor ${anchor} points outside ${path} (${lines.length} lines). Read the file again and use a current anchor.`,
    );
  }

  const actualHash = computeLineHash(lines[lineIndex]);
  if (actualHash !== parsed.hash) {
    const currentAnchor = `${parsed.line}:${actualHash}`;
    throw new Error(
      `Anchor mismatch for ${anchor} in ${path}. Current anchor at line ${parsed.line} is ${currentAnchor}. Re-read the file before editing.`,
    );
  }

  return lineIndex;
}

function generateDiffString(
  oldContent: string,
  newContent: string,
  contextLines = 4,
): EditDiffResult {
  const oldLines = oldContent.split("\n");
  const newLines = newContent.split("\n");
  const maxLineNumber = Math.max(oldLines.length, newLines.length);
  const lineNumberWidth = String(maxLineNumber).length;

  let start = 0;
  const minLength = Math.min(oldLines.length, newLines.length);
  while (start < minLength && oldLines[start] === newLines[start]) {
    start++;
  }

  if (start === oldLines.length && start === newLines.length) {
    return { diff: "", firstChangedLine: undefined };
  }

  let oldEnd = oldLines.length - 1;
  let newEnd = newLines.length - 1;
  while (
    oldEnd >= start &&
    newEnd >= start &&
    oldLines[oldEnd] === newLines[newEnd]
  ) {
    oldEnd--;
    newEnd--;
  }

  const firstChangedLine = start + 1;
  const output: string[] = [];

  const beforeStart = Math.max(0, start - contextLines);
  const beforeContext = oldLines.slice(beforeStart, start);
  const removedLines = oldLines.slice(start, oldEnd + 1);
  const addedLines = newLines.slice(start, newEnd + 1);
  const afterContextEnd = Math.min(oldLines.length, oldEnd + 1 + contextLines);
  const afterContext = oldLines.slice(oldEnd + 1, afterContextEnd);

  if (beforeStart > 0) {
    output.push(` ${"".padStart(lineNumberWidth, " ")} ...`);
  }

  for (let index = 0; index < beforeContext.length; index++) {
    const lineNumber = beforeStart + index + 1;
    output.push(
      ` ${String(lineNumber).padStart(lineNumberWidth, " ")} ${beforeContext[index]}`,
    );
  }

  for (let index = 0; index < removedLines.length; index++) {
    const lineNumber = firstChangedLine + index;
    output.push(
      `-${String(lineNumber).padStart(lineNumberWidth, " ")} ${removedLines[index]}`,
    );
  }

  for (let index = 0; index < addedLines.length; index++) {
    const lineNumber = firstChangedLine + index;
    output.push(
      `+${String(lineNumber).padStart(lineNumberWidth, " ")} ${addedLines[index]}`,
    );
  }

  for (let index = 0; index < afterContext.length; index++) {
    const lineNumber = oldEnd + index + 2;
    output.push(
      ` ${String(lineNumber).padStart(lineNumberWidth, " ")} ${afterContext[index]}`,
    );
  }

  if (afterContextEnd < oldLines.length) {
    output.push(` ${"".padStart(lineNumberWidth, " ")} ...`);
  }

  return {
    diff: output.join("\n"),
    firstChangedLine,
  };
}

function parseAnchoredOperation(
  operation: HashlineEdit,
  lines: string[],
  path: string,
): AnchoredOperation | null {
  if ("set_line" in operation) {
    const lineIndex = validateAnchor(operation.set_line.anchor, lines, path);
    return {
      type: "set_line",
      startLineIndex: lineIndex,
      endLineIndex: lineIndex,
      text: normalizeToLf(operation.set_line.new_text),
    };
  }

  if ("replace_lines" in operation) {
    const startLineIndex = validateAnchor(
      operation.replace_lines.start_anchor,
      lines,
      path,
    );
    const endLineIndex = validateAnchor(
      operation.replace_lines.end_anchor,
      lines,
      path,
    );

    if (endLineIndex < startLineIndex) {
      throw new Error(
        `Invalid replace_lines range (${operation.replace_lines.start_anchor}..${operation.replace_lines.end_anchor}). End must be after start.`,
      );
    }

    return {
      type: "replace_lines",
      startLineIndex,
      endLineIndex,
      text: normalizeToLf(operation.replace_lines.new_text),
    };
  }

  if ("insert_after" in operation) {
    const lineIndex = validateAnchor(
      operation.insert_after.anchor,
      lines,
      path,
    );
    return {
      type: "insert_after",
      startLineIndex: lineIndex,
      endLineIndex: lineIndex,
      text: normalizeToLf(operation.insert_after.text),
    };
  }

  return null;
}

function applyAnchoredOperations(
  baseLines: string[],
  operations: AnchoredOperation[],
): string[] {
  const nextLines = [...baseLines];
  const sorted = [...operations].sort((a, b) => {
    if (a.startLineIndex !== b.startLineIndex) {
      return b.startLineIndex - a.startLineIndex;
    }

    return b.endLineIndex - a.endLineIndex;
  });

  for (const operation of sorted) {
    const replacementLines = operation.text.split("\n");

    if (operation.type === "insert_after") {
      nextLines.splice(operation.startLineIndex + 1, 0, ...replacementLines);
      continue;
    }

    nextLines.splice(
      operation.startLineIndex,
      operation.endLineIndex - operation.startLineIndex + 1,
      ...replacementLines,
    );
  }

  return nextLines;
}

function applyReplaceOperations(
  content: string,
  operations: HashlineEdit[],
  path: string,
): string {
  let nextContent = content;

  for (const operation of operations) {
    if (!("replace" in operation)) {
      continue;
    }

    const oldText = normalizeToLf(operation.replace.old_text);
    const newText = normalizeToLf(operation.replace.new_text);

    if (!oldText) {
      throw new Error(`replace.old_text cannot be empty for ${path}.`);
    }

    const occurrences = nextContent.split(oldText).length - 1;
    if (occurrences === 0) {
      throw new Error(
        `Could not find replace.old_text in ${path}. Re-read the file and try again.`,
      );
    }

    if (occurrences > 1) {
      throw new Error(
        `replace.old_text appears ${occurrences} times in ${path}. Provide more surrounding context so it is unique.`,
      );
    }

    nextContent = nextContent.replace(oldText, newText);
  }

  return nextContent;
}

function formatHashlineOutput(
  lines: string[],
  startLine: number,
  path: string,
  truncation: TruncationResult,
  totalFileLines: number,
  userLimitedLines?: number,
): { text: string; details?: { truncation: TruncationResult } } {
  const startLineDisplay = startLine + 1;

  if (truncation.firstLineExceedsLimit) {
    const firstLineSize = formatSize(
      Buffer.byteLength(lines[startLine] ?? "", "utf-8"),
    );
    return {
      text:
        `[Line ${startLineDisplay} is ${firstLineSize}, exceeds ${formatSize(DEFAULT_MAX_BYTES)} limit. ` +
        `Use bash to inspect a slice, for example: sed -n '${startLineDisplay}p' ${path} | head -c ${DEFAULT_MAX_BYTES}]`,
      details: { truncation },
    };
  }

  if (truncation.truncated) {
    const endLineDisplay = startLineDisplay + truncation.outputLines - 1;
    const nextOffset = endLineDisplay + 1;

    let text = truncation.content;
    if (truncation.truncatedBy === "lines") {
      text += `\n\n[Showing lines ${startLineDisplay}-${endLineDisplay} of ${totalFileLines}. Use offset=${nextOffset} to continue.]`;
    } else {
      text +=
        `\n\n[Showing lines ${startLineDisplay}-${endLineDisplay} of ${totalFileLines} ` +
        `(${formatSize(DEFAULT_MAX_BYTES)} limit). Use offset=${nextOffset} to continue.]`;
    }

    return {
      text,
      details: { truncation },
    };
  }

  if (
    userLimitedLines !== undefined &&
    startLine + userLimitedLines < totalFileLines
  ) {
    const remaining = totalFileLines - (startLine + userLimitedLines);
    const nextOffset = startLine + userLimitedLines + 1;
    return {
      text: `${truncation.content}\n\n[${remaining} more lines in file. Use offset=${nextOffset} to continue.]`,
    };
  }

  return { text: truncation.content };
}

export default function (pi: ExtensionAPI) {
  pi.registerTool({
    name: "read",
    label: "read (hashline)",
    description:
      "Read a file with hashline tags for each text line: <line>:<hash>|<content>. " +
      "Use these anchors with the hashline edit tool. Supports offset/limit and truncates at 2000 lines or 50KB.",
    parameters: readSchema,
    async execute(toolCallId, params: ReadInput, signal, onUpdate, ctx) {
      const path = normalizeInputPath(params.path);
      const absolutePath = resolve(ctx.cwd, path);

      if (IMAGE_EXT_RE.test(path)) {
        const readTool = createReadTool(ctx.cwd);
        return readTool.execute(
          toolCallId,
          { ...params, path },
          signal,
          onUpdate,
          ctx,
        );
      }

      await access(absolutePath, constants.R_OK);
      const buffer = await readFile(absolutePath);
      const textContent = buffer.toString("utf-8");
      const lines = textContent.split("\n");
      const totalFileLines = lines.length;

      const startLine = params.offset ? Math.max(0, params.offset - 1) : 0;
      if (startLine >= lines.length) {
        throw new Error(
          `Offset ${params.offset} is beyond end of file (${lines.length} lines total).`,
        );
      }

      let selectedLines: string[];
      let userLimitedLines: number | undefined;
      if (params.limit !== undefined) {
        const endLine = Math.min(startLine + params.limit, lines.length);
        selectedLines = lines.slice(startLine, endLine);
        userLimitedLines = endLine - startLine;
      } else {
        selectedLines = lines.slice(startLine);
      }

      const hashlines = selectedLines.map((line, index) =>
        formatHashline(line, startLine + index + 1),
      );
      const truncation = truncateHead(hashlines.join("\n"), {
        maxLines: DEFAULT_MAX_LINES,
        maxBytes: DEFAULT_MAX_BYTES,
      });

      const formatted = formatHashlineOutput(
        lines,
        startLine,
        path,
        truncation,
        totalFileLines,
        userLimitedLines,
      );

      return {
        content: [{ type: "text", text: formatted.text }],
        details: formatted.details,
      };
    },
  });

  pi.registerTool({
    name: "edit",
    label: "edit (hashline)",
    description:
      "Edit files using hashline anchors from read output. " +
      "Operations: set_line, replace_lines, insert_after, replace (fallback exact unique text). " +
      "Anchored edits are rejected if the file changed since read.",
    parameters: editSchema,
    async execute(_toolCallId, params: EditInput, _signal, _onUpdate, ctx) {
      const path = normalizeInputPath(params.path);
      const absolutePath = resolve(ctx.cwd, path);

      await access(absolutePath, constants.R_OK | constants.W_OK);

      const rawContent = (await readFile(absolutePath)).toString("utf-8");
      const { bom, text } = stripBom(rawContent);
      const originalLineEnding = detectLineEnding(text);
      const normalizedOriginal = normalizeToLf(text);
      const originalLines = normalizedOriginal.split("\n");

      const anchoredOperations = params.edits
        .map((operation) =>
          parseAnchoredOperation(operation, originalLines, path),
        )
        .filter(
          (operation): operation is AnchoredOperation => operation !== null,
        );

      const withAnchorsApplied = applyAnchoredOperations(
        originalLines,
        anchoredOperations,
      ).join("\n");
      const normalizedNext = applyReplaceOperations(
        withAnchorsApplied,
        params.edits,
        path,
      );

      if (normalizedNext === normalizedOriginal) {
        throw new Error(`No changes made to ${path}.`);
      }

      const finalContent =
        bom + restoreLineEndings(normalizedNext, originalLineEnding);
      await writeFile(absolutePath, finalContent, "utf-8");

      const diffResult = generateDiffString(normalizedOriginal, normalizedNext);

      return {
        content: [
          {
            type: "text",
            text: `Successfully applied ${params.edits.length} edit operation(s) to ${path}.`,
          },
        ],
        details: {
          diff: diffResult.diff,
          firstChangedLine: diffResult.firstChangedLine,
        },
      };
    },
  });
}
