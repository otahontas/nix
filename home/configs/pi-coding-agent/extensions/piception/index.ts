import { complete } from "@mariozechner/pi-ai";
import type {
  ExtensionAPI,
  ExtensionCommandContext,
  ExtensionContext,
} from "@mariozechner/pi-coding-agent";
import * as fs from "node:fs";
import * as path from "node:path";
import { exec } from "node:child_process";
import { promisify } from "node:util";

const execAsync = promisify(exec);

// ============================================================================
// Skill Search and Keywords
// ============================================================================

/**
 * Checks if brave-search skill is available.
 */
function getBraveSearchPath(): string | null {
  const skillsDir = path.join(
    require("os").homedir(),
    ".pi",
    "agent",
    "skills",
    "brave-search",
  );
  const searchScript = path.join(skillsDir, "search.js");

  if (fs.existsSync(searchScript)) {
    return searchScript;
  }

  return null;
}

/**
 * Extracts technology names from conversation context.
 */
function extractTechnologies(conversationText: string): string[] {
  const techPatterns = [
    /\b(nextjs|next\.js|react|prisma|typescript|node\.?js|postgres|mongodb|docker|kubernetes|tailwind|vue|angular)\b/gi,
    /\b(npm|yarn|pnpm|webpack|vite|rollup|eslint|prettier|jest|vitest)\b/gi,
  ];

  const technologies = new Set<string>();
  for (const pattern of techPatterns) {
    const matches = conversationText.match(pattern);
    if (matches) {
      matches.forEach((m) => technologies.add(m.toLowerCase()));
    }
  }

  return Array.from(technologies);
}

/**
 * Extracts error snippets from conversation context.
 */
function extractErrorSnippets(conversationText: string): string[] {
  const errorPatterns = [
    /(?:^|\n)\s*(?:[A-Za-z]*Error|Exception): [^\n]{10,160}/g,
    /\b(ENOENT|ECONNREFUSED|ECONNRESET|ETIMEDOUT|EACCES|EADDRINUSE): [^\n]{5,160}/g,
  ];

  const errors = new Set<string>();
  for (const pattern of errorPatterns) {
    const matches = conversationText.match(pattern);
    if (matches) {
      matches.forEach((m) => errors.add(m.trim()));
    }
  }

  return Array.from(errors).slice(0, 5);
}

/**
 * Extracts context markers like file names or config files.
 */
function extractContextMarkers(conversationText: string): string[] {
  const markers = new Set<string>();
  const filePattern =
    /\b[\w./-]+\.(?:js|jsx|ts|tsx|json|yaml|yml|toml|md|schema|lock|config)\b/gi;
  const configPattern = /\b[\w.-]+\.config\.(?:js|ts|mjs|cjs)\b/gi;

  const fileMatches = conversationText.match(filePattern);
  if (fileMatches) {
    fileMatches.forEach((m) => markers.add(m));
  }

  const configMatches = conversationText.match(configPattern);
  if (configMatches) {
    configMatches.forEach((m) => markers.add(m));
  }

  return Array.from(markers).slice(0, 10);
}

/**
 * Builds search queries from conversation context.
 */
function buildSearchQueries(conversationText: string): string[] {
  const queries: string[] = [];
  const technologies = extractTechnologies(conversationText);
  const errors = extractErrorSnippets(conversationText);

  const truncate = (value: string, max: number) =>
    value.length > max ? `${value.slice(0, max)}...` : value;

  if (technologies.length > 0 && errors.length > 0) {
    const tech = technologies[0];
    const error = truncate(errors[0], 80);
    queries.push(`"${tech} ${error}" fix`);
  } else if (errors.length > 0) {
    const error = truncate(errors[0], 80);
    queries.push(`"${error}" fix`);
  }

  if (technologies.length > 0) {
    const tech = technologies[0];
    queries.push(`"${tech}" official documentation`);
  }

  return queries.slice(0, 2);
}

/**
 * Determines whether web research is appropriate for the conversation.
 */
function shouldPerformWebResearch(conversationText: string): boolean {
  const technologies = extractTechnologies(conversationText);
  const errors = extractErrorSnippets(conversationText);

  if (technologies.length === 0 && errors.length === 0) {
    return false;
  }

  const internalMarkers = [
    /\/Users\//i,
    /\/home\//i,
    /\\Users\\/i,
    /\.pi[\\/]/i,
  ];

  return !internalMarkers.some((marker) => marker.test(conversationText));
}

/**
 * Performs web search using brave-search skill.
 */
async function performWebResearch(
  conversationText: string,
): Promise<string | null> {
  const searchScript = getBraveSearchPath();

  if (!searchScript) {
    return null;
  }

  if (!shouldPerformWebResearch(conversationText)) {
    return null;
  }

  const queries = buildSearchQueries(conversationText);

  if (queries.length === 0) {
    return null;
  }

  let hasLoggedUnavailable = false;
  const results: string[] = [];

  for (const query of queries) {
    try {
      const { stdout, stderr } = await execAsync(
        `node "${searchScript}" "${query}" -n 3`,
        {
          timeout: 5000, // 5 second timeout per search
          env: { ...process.env },
        },
      );

      if (stdout && stdout.trim()) {
        results.push(`Query: ${query}\n${stdout.trim()}`);
      }

      if (stderr && !hasLoggedUnavailable) {
        console.warn("Brave search stderr:", stderr);
      }
    } catch (error: any) {
      if (!hasLoggedUnavailable) {
        if (error.code === "ENOENT") {
          console.log(
            "Web search unavailable (brave-search not installed), skipping references",
          );
        } else if (error.killed) {
          console.log("Web search timed out, skipping references");
        } else {
          console.log(
            `Web search failed: ${error.message}, skipping references`,
          );
        }
        hasLoggedUnavailable = true;
      }
      // Continue with next query or return what we have
    }
  }

  return results.length > 0 ? results.join("\n\n---\n\n") : null;
}

/**
 * Extracts potential keywords from conversation text for skill searching.
 */
function extractKeywords(text: string): string[] {
  // Simple keyword extraction: words longer than 3 chars, lowercase, filter common words
  const words = text.toLowerCase().match(/\b\w{4,}\b/g) || [];
  const common = new Set([
    "this",
    "that",
    "with",
    "from",
    "have",
    "been",
    "will",
    "your",
    "they",
    "their",
    "what",
    "when",
    "where",
    "which",
    "there",
    "here",
    "then",
    "than",
    "some",
    "come",
    "were",
    "said",
    "each",
    "very",
    "much",
    "most",
    "other",
    "such",
    "into",
    "only",
    "also",
    "even",
    "just",
    "over",
    "after",
    "before",
    "during",
    "while",
    "since",
    "until",
    "through",
    "about",
    "above",
    "below",
    "between",
    "among",
    "around",
    "behind",
    "beside",
    "beyond",
    "inside",
    "outside",
    "under",
    "upon",
    "within",
    "without",
    "against",
    "along",
    "across",
    "towards",
    "throughout",
    "despite",
    "although",
    "because",
    "though",
    "unless",
    "until",
    "whereas",
    "whether",
    "error",
    "code",
    "file",
    "function",
    "class",
    "import",
    "export",
    "const",
    "type",
    "interface",
    "async",
    "await",
    "return",
    "throw",
    "catch",
    "try",
    "component",
    "props",
    "state",
    "effect",
    "hook",
    "event",
    "handler",
    "data",
    "value",
    "result",
    "request",
    "response",
    "server",
    "client",
    "browser",
    "database",
    "query",
    "table",
    "column",
    "model",
    "schema",
    "route",
    "path",
    "method",
    "status",
    "header",
    "body",
    "json",
    "string",
    "number",
    "boolean",
    "array",
    "object",
    "null",
    "undefined",
    "true",
    "false",
    "for",
    "if",
    "else",
    "switch",
    "case",
    "default",
    "while",
    "do",
    "break",
    "continue",
    "function",
    "var",
    "let",
    "console",
    "log",
    "debug",
    "info",
    "warn",
    "trace",
    "test",
    "spec",
    "mock",
    "stub",
    "fixture",
    "config",
    "build",
    "start",
    "stop",
    "run",
    "install",
    "update",
    "delete",
    "create",
    "read",
    "write",
    "edit",
    "save",
    "load",
    "parse",
    "stringify",
    "encode",
    "decode",
    "hash",
    "encrypt",
    "decrypt",
  ]);
  return [...new Set(words.filter((w) => !common.has(w)))].slice(0, 20); // Limit to 20 keywords
}

type SkillSearchTerms = {
  keywords: string[];
  errorSnippets: string[];
  contextMarkers: string[];
};

function buildSkillSearchTerms(conversationText: string): SkillSearchTerms {
  return {
    keywords: extractKeywords(conversationText),
    errorSnippets: extractErrorSnippets(conversationText),
    contextMarkers: extractContextMarkers(conversationText),
  };
}

/**
 * Searches existing skills using ripgrep for keywords and context markers.
 */
async function searchExistingSkills(
  searchTerms: SkillSearchTerms,
): Promise<ExistingSkill[]> {
  const dirs = [
    path.join(require("os").homedir(), ".pi", "agent", "skills"),
    path.join(process.cwd(), ".pi", "skills"),
    path.join(require("os").homedir(), ".claude", "skills"),
    path.join(process.cwd(), ".claude", "skills"),
    path.join(require("os").homedir(), ".codex", "skills"),
    path.join(process.cwd(), ".codex", "skills"),
  ];

  const existingDirs = dirs.filter((d) => fs.existsSync(d));
  if (existingDirs.length === 0) return [];

  // Find all SKILL.md files first.
  const allSkillFiles: string[] = [];
  for (const dir of existingDirs) {
    try {
      const out = await execAsync(
        `find "${dir}" -name SKILL.md -type f 2>/dev/null || true`,
      );
      const files = out.stdout
        .split("\n")
        .map((l) => l.trim())
        .filter(Boolean);
      allSkillFiles.push(...files);
    } catch {
      // ignore
    }
  }

  const hasSearchTerms =
    searchTerms.keywords.length > 0 ||
    searchTerms.errorSnippets.length > 0 ||
    searchTerms.contextMarkers.length > 0;

  // If we have search terms, filter files by ripgrep; otherwise parse all.
  let matchingFiles = allSkillFiles;
  if (hasSearchTerms) {
    const matches = new Set<string>();
    const dirArgs = existingDirs.map((d) => `"${d}"`).join(" ");
    const skillGlob = '-g "SKILL.md"';

    const buildFixedArgs = (values: string[]) =>
      values.map((value) => `-e ${JSON.stringify(value)}`).join(" ");

    const runSearch = async (cmd: string) => {
      try {
        const out = await execAsync(cmd, { timeout: 5000 });
        return out.stdout
          .split("\n")
          .map((l) => l.trim())
          .filter((f) => f.endsWith("SKILL.md"));
      } catch {
        return [];
      }
    };

    if (searchTerms.keywords.length > 0) {
      const pattern = searchTerms.keywords.map((k) => `(${k})`).join("|");
      const cmd = `rg -il ${skillGlob} "${pattern}" ${dirArgs} || true`;
      const files = await runSearch(cmd);
      files.forEach((file) => matches.add(file));
    }

    if (searchTerms.contextMarkers.length > 0) {
      const markerArgs = buildFixedArgs(searchTerms.contextMarkers);
      const cmd = `rg -F -il ${skillGlob} ${markerArgs} ${dirArgs} || true`;
      const files = await runSearch(cmd);
      files.forEach((file) => matches.add(file));
    }

    if (searchTerms.errorSnippets.length > 0) {
      const errorArgs = buildFixedArgs(searchTerms.errorSnippets);
      const cmd = `rg -F -il ${skillGlob} ${errorArgs} ${dirArgs} || true`;
      const files = await runSearch(cmd);
      files.forEach((file) => matches.add(file));
    }

    matchingFiles = [...matches];
  }

  const parsed: ExistingSkill[] = [];
  for (const file of matchingFiles) {
    try {
      parsed.push(parseExistingSkill(file));
    } catch (e) {
      // Skip invalid skills rather than failing extraction.
      console.warn("Failed to parse existing skill:", file, e);
    }
  }

  return parsed;
}

// ============================================================================
// Types
// ============================================================================

type SessionEntry = {
  type: string;
  message?: {
    role?: string;
    content?: unknown;
    toolName?: string;
    details?: Record<string, unknown>;
  };
};

type ContentBlock = {
  type?: string;
  text?: string;
  name?: string;
};

type ExistingSkill = {
  name: string;
  version: string;
  path: string;
  description: string;
  problem: string;
  triggers: string[];
};

type VersionBump = "patch" | "minor" | "major";

type SkillDecision = {
  action: "create" | "update" | "skip";
  versionBump?: VersionBump;
  existingSkillPath?: string;
  crossReferences?: string[];
  reason: string;
};

type SkillCandidate = {
  name: string;
  description: string;
  content: string;
  quality: "high" | "medium" | "low";
  reason: string;

  // Decision returned by the model (or computed by compareSkills)
  action: "create" | "update" | "skip";
  versionBump?: VersionBump;
  existingSkillPath?: string;
  crossReferences?: string[];
};

// ============================================================================
// Versioning + existing skill parsing
// ============================================================================

function parseVersion(version: string): {
  major: number;
  minor: number;
  patch: number;
} {
  const match = version.trim().match(/^(\d+)\.(\d+)\.(\d+)$/);
  if (!match) {
    throw new Error(
      `Invalid version: '${version}' (expected MAJOR.MINOR.PATCH)`,
    );
  }
  return {
    major: Number(match[1]),
    minor: Number(match[2]),
    patch: Number(match[3]),
  };
}

function bumpVersion(version: string, bump: VersionBump): string {
  const v = parseVersion(version);
  if (bump === "patch") return `${v.major}.${v.minor}.${v.patch + 1}`;
  if (bump === "minor") return `${v.major}.${v.minor + 1}.0`;
  return `${v.major + 1}.0.0`;
}

function extractFrontmatter(md: string): { frontmatter: string; body: string } {
  const trimmed = md.trimStart();
  if (!trimmed.startsWith("---")) return { frontmatter: "", body: md };
  const end = trimmed.indexOf("\n---", 3);
  if (end === -1) return { frontmatter: "", body: md };
  const fm = trimmed.slice(3, end + 1).trim();
  const body = trimmed.slice(end + "\n---".length).trimStart();
  return { frontmatter: fm, body };
}

function frontmatterGetScalar(fm: string, key: string): string | null {
  // Handles: key: value
  const re = new RegExp(`^${key}\\s*:\\s*(.+)$`, "m");
  const m = fm.match(re);
  if (!m) return null;
  return m[1].trim().replace(/^"|"$/g, "").replace(/^'|'$/g, "");
}

function frontmatterGetBlock(fm: string, key: string): string | null {
  // Handles:
  // description: |
  //   line1
  //   line2
  const lines = fm.split("\n");
  const idx = lines.findIndex((l) => l.trimStart().startsWith(`${key}:`));
  if (idx === -1) return null;
  const line = lines[idx];
  if (!line.includes("|")) {
    const scalar = line.split(":").slice(1).join(":").trim();
    return scalar || null;
  }
  const out: string[] = [];
  for (let i = idx + 1; i < lines.length; i++) {
    const l = lines[i];
    if (/^\w[\w-]*\s*:/.test(l)) break; // next top-level key
    out.push(l.replace(/^\s{2}/, ""));
  }
  const text = out.join("\n").trim();
  return text || null;
}

function extractSection(mdBody: string, heading: string): string {
  // Extract content under '## Heading' until next '##'
  const re = new RegExp(
    `^##\\s+${heading.replace(/[.*+?^${}()|[\\]\\]/g, "\\$&")}\\s*$`,
    "mi",
  );
  const m = mdBody.match(re);
  if (!m || m.index == null) return "";
  const start = m.index + m[0].length;
  const rest = mdBody.slice(start);
  const next = rest.match(/^##\s+/m);
  const section = next && next.index != null ? rest.slice(0, next.index) : rest;
  return section.trim();
}

function extractTriggersFromSection(section: string): string[] {
  const triggers: string[] = [];
  for (const raw of section.split("\n")) {
    const line = raw.trim();
    if (!line) continue;
    const bullet = line.match(/^[-*]\s+(.*)$/);
    if (bullet) {
      triggers.push(bullet[1].trim());
      continue;
    }
    // Heuristic: lines under "This skill applies when" or similar may be plain
    if (!line.startsWith("```") && line.length < 200) {
      triggers.push(line);
    }
  }
  return [...new Set(triggers)].slice(0, 30);
}

function parseExistingSkill(skillPath: string): ExistingSkill {
  const md = fs.readFileSync(skillPath, "utf-8");
  const { frontmatter, body } = extractFrontmatter(md);

  const name =
    frontmatterGetScalar(frontmatter, "name") ||
    path.basename(path.dirname(skillPath));
  const version = frontmatterGetScalar(frontmatter, "version") || "0.0.0";
  // Validate version format early
  parseVersion(version);

  const description =
    frontmatterGetBlock(frontmatter, "description") ||
    frontmatterGetScalar(frontmatter, "description") ||
    "";

  const problem = extractSection(body, "Problem");
  const context =
    extractSection(body, "Context / Trigger Conditions") ||
    extractSection(body, "Context") ||
    "";

  const triggers = extractTriggersFromSection(context);

  return {
    name,
    version,
    path: skillPath,
    description: description.trim(),
    problem: problem.trim(),
    triggers,
  };
}

function compareSkills(
  existing: ExistingSkill,
  candidate: SkillCandidate,
): SkillDecision {
  const existingProblem = existing.problem.toLowerCase();
  const candContent = (candidate.content || "").toLowerCase();
  const candDesc = (candidate.description || "").toLowerCase();

  const hasSameProblem =
    existingProblem.length > 0 &&
    (candContent.includes(
      existingProblem.slice(0, Math.min(80, existingProblem.length)),
    ) ||
      candDesc.includes(
        existingProblem.slice(0, Math.min(80, existingProblem.length)),
      ));

  const existingTriggersNorm = new Set(
    existing.triggers.map((t) => t.toLowerCase()),
  );
  const candTriggersText = `${candContent}\n${candDesc}`;
  const matchedTriggers = [...existingTriggersNorm].filter(
    (t) => t.length > 6 && candTriggersText.includes(t),
  );
  const triggerOverlap =
    existingTriggersNorm.size === 0
      ? 0
      : matchedTriggers.length / existingTriggersNorm.size;

  if (hasSameProblem && triggerOverlap >= 0.6) {
    return {
      action: "update",
      versionBump: "patch",
      existingSkillPath: existing.path,
      reason:
        "Same problem and largely same triggers; treat as a small refinement.",
    };
  }

  if (hasSameProblem && triggerOverlap < 0.6) {
    return {
      action: "update",
      versionBump: "minor",
      existingSkillPath: existing.path,
      reason:
        "Same problem but new or different trigger conditions; add new scenario.",
    };
  }

  // Heuristic: similar domain if name shares a token
  const existingTokens = new Set(existing.name.split("-"));
  const candTokens = new Set(candidate.name.split("-"));
  const shared = [...existingTokens].some(
    (t) => candTokens.has(t) && t.length > 3,
  );

  if (shared) {
    return {
      action: "create",
      crossReferences: [existing.name],
      reason:
        "Different problem but similar domain; create new skill and cross-reference.",
    };
  }

  return {
    action: "create",
    reason: "No strong match with existing skills.",
  };
}

// ============================================================================
// Session Analysis
// ============================================================================

/**
 * Extracts text content from message content blocks.
 */
function extractTextParts(content: unknown): string[] {
  if (typeof content === "string") {
    return [content];
  }

  if (!Array.isArray(content)) {
    return [];
  }

  const textParts: string[] = [];
  for (const part of content) {
    if (!part || typeof part !== "object") {
      continue;
    }

    const block = part as ContentBlock;
    if (block.type === "text" && typeof block.text === "string") {
      textParts.push(block.text);
    }
  }

  return textParts;
}

/**
 * Builds a conversation history string from session entries.
 */
function buildConversationText(entries: SessionEntry[]): string {
  const sections: string[] = [];

  for (const entry of entries) {
    if (entry.type !== "message" || !entry.message?.role) {
      continue;
    }

    const role = entry.message.role;
    if (role !== "user" && role !== "assistant") {
      continue;
    }

    const textParts = extractTextParts(entry.message.content);
    if (textParts.length > 0) {
      const roleLabel = role === "user" ? "User" : "Assistant";
      const messageText = textParts.join("\n").trim();
      if (messageText.length > 0) {
        sections.push(`${roleLabel}: ${messageText}`);
      }
    }
  }

  return sections.join("\n\n");
}

// ============================================================================
// Skill Extraction
// ============================================================================

/**
 * Loads the extraction prompt template.
 */
function loadExtractionPrompt(): string {
  const promptPath = path.join(__dirname, "extraction-prompt.md");
  try {
    return fs.readFileSync(promptPath, "utf-8");
  } catch (error) {
    const message = `Failed to load extraction prompt: ${promptPath}`;
    console.error(message, error);
    throw new Error(message);
  }
}

/**
 * Loads the skill template.
 */
function loadSkillTemplate(): string {
  const templatePath = path.join(__dirname, "skill-template.md");
  try {
    return fs.readFileSync(templatePath, "utf-8");
  } catch (error) {
    const message = `Failed to load skill template: ${templatePath}`;
    console.error(message, error);
    throw new Error(message);
  }
}

/**
 * Uses LLM to analyze the session and identify skill candidates.
 */
async function identifySkillCandidates(
  conversationText: string,
  ctx: ExtensionContext,
): Promise<SkillCandidate[] | null> {
  const model = ctx.model;
  if (!model) {
    console.warn(
      "Piception: Cannot extract skills - no model configured. Please configure a model to use skill extraction.",
    );
    return null;
  }

  const apiKey = await ctx.modelRegistry.getApiKey(model);
  if (!apiKey) {
    console.warn(
      `Piception: Cannot extract skills - no API key found for model '${model}'. Please configure an API key for this model.`,
    );
    return null;
  }

  // Extract search terms and search existing skills
  const searchTerms = buildSkillSearchTerms(conversationText);
  const existingSkills = await searchExistingSkills(searchTerms);

  // Perform web research for additional context
  const webResearch = await performWebResearch(conversationText);

  const prompt = loadExtractionPrompt();
  const existingSkillsJson = JSON.stringify(existingSkills, null, 2);
  let fullPrompt = `${prompt}\n\n<conversation>\n${conversationText}\n</conversation>\n\n<existing-skills-json>\n${existingSkillsJson}\n</existing-skills-json>`;

  if (webResearch) {
    fullPrompt += `\n\n<web-research>\n${webResearch}\n</web-research>\n\nWhen creating the skill, include a "References" section with relevant URLs from the web research above. Only include references that are directly relevant to the problem and solution.`;
  }

  fullPrompt += `\n\nReturn your analysis as a JSON array of skill candidates.`;

  const messages = [
    {
      role: "user" as const,
      content: [{ type: "text" as const, text: fullPrompt }],
      timestamp: Date.now(),
    },
  ];

  try {
    const response = await complete(
      model,
      { messages },
      { apiKey, reasoningEffort: "medium" },
    );

    const responseText = response.content
      .filter((c): c is { type: "text"; text: string } => c.type === "text")
      .map((c) => c.text)
      .join("\n");

    // Try to parse JSON response
    const jsonMatch = responseText.match(/\[[\s\S]*\]/);
    if (jsonMatch) {
      try {
        const candidates = JSON.parse(jsonMatch[0]) as SkillCandidate[];
        return candidates.filter(
          (c) => c.quality === "high" || c.quality === "medium",
        );
      } catch (parseError) {
        console.error(
          "Piception: Failed to parse JSON from LLM response:",
          parseError,
        );
        console.error(
          "Raw matched text:",
          jsonMatch[0].length > 500
            ? jsonMatch[0].substring(0, 500) + "..."
            : jsonMatch[0],
        );
        return null;
      }
    }

    // Log warning when no JSON array found in response
    console.warn(
      "Malformed LLM response - no JSON array found in response:",
      responseText.length > 200
        ? responseText.substring(0, 200) + "..."
        : responseText,
    );
    return null;
  } catch (error) {
    console.error(
      "Piception: API call failed while identifying skill candidates:",
      error,
    );
    return null;
  }
}

/**
 * Creates a skill file at the specified location.
 */
function createSkill(
  name: string,
  content: string,
  userWide: boolean,
  ctx: ExtensionContext,
): boolean {
  const baseDir = userWide
    ? path.join(require("os").homedir(), ".pi", "agent", "skills")
    : path.join(ctx.cwd, ".pi", "skills");

  const skillDir = path.join(baseDir, name);
  const skillFile = path.join(skillDir, "SKILL.md");

  try {
    // Create directory if it doesn't exist
    try {
      fs.mkdirSync(skillDir, { recursive: true });
    } catch (error: any) {
      console.error(
        `Failed to create skill directory at ${skillDir}:`,
        error?.code || error?.message || error,
      );
      return false;
    }

    // Write skill file
    try {
      fs.writeFileSync(skillFile, content, "utf-8");
    } catch (error: any) {
      console.error(
        `Failed to write skill file at ${skillFile}:`,
        error?.code || error?.message || error,
      );
      return false;
    }

    return true;
  } catch (error) {
    console.error("Unexpected error creating skill:", error);
    return false;
  }
}

/**
 * Creates skills interactively from candidates with user review/edit/skip.
 */
async function createSkillsInteractively(
  candidates: SkillCandidate[],
  ctx: ExtensionContext,
): Promise<void> {
  // Headless mode: keep current behavior (auto-apply, no prompts)
  if (!ctx.hasUI) {
    await createSkillsHeadless(candidates, ctx);
    return;
  }

  if (candidates.length === 0) {
    ctx.ui.notify("No extractable skills found in this session", "info");
    return;
  }

  // Load template
  const template = loadSkillTemplate();

  for (const candidate of candidates) {
    if (candidate.action === "skip") {
      ctx.ui.notify(
        `Skipped (model): ${candidate.name} (${candidate.reason})`,
        "info",
      );
      continue;
    }

    // Preview (name, description, first 10 lines)
    const previewLines = (candidate.content || "")
      .split("\n")
      .slice(0, 10)
      .join("\n");
    ctx.ui.notify(
      `Candidate: ${candidate.name}\n${candidate.description}\n\n${previewLines}`,
      "info",
    );

    const review = await promptUserReview(candidate, ctx);
    if (review === "skip") {
      ctx.ui.notify(`Skipped: ${candidate.name}`, "info");
      continue;
    }

    // Generate skill content from template or use provided content
    const now = new Date();
    const dateStr = now.toISOString().split("T")[0];

    let skillContent = candidate.content || template;
    skillContent = skillContent.replace(/{{NAME}}/g, candidate.name);
    skillContent = skillContent.replace(
      /{{DESCRIPTION}}/g,
      candidate.description,
    );
    skillContent = skillContent.replace(/{{DATE}}/g, dateStr);
    skillContent = skillContent.replace(
      /{{TITLE}}/g,
      candidate.name
        .split("-")
        .filter((w) => w.length > 0)
        .map((w) => w[0].toUpperCase() + w.slice(1))
        .join(" "),
    );

    if (review === "edit") {
      // First try Pi's built-in multi-line editor dialog
      const edited = await ctx.ui.editor(
        `Edit skill content: ${candidate.name}`,
        skillContent,
      );
      skillContent = typeof edited === "string" ? edited : skillContent;

      // Optional external editor pass (only if user has $EDITOR/$VISUAL)
      // This is a no-op if no env editor is configured.
      skillContent = await editSkillContent(skillContent, candidate.name);
    }

    const locationChoice = await chooseSkillLocation(ctx);
    const userWide = locationChoice === "user";

    let success = false;
    let location = "";

    if (candidate.action === "update") {
      const existingPath = candidate.existingSkillPath;
      if (!existingPath) {
        ctx.ui.notify(
          `Missing existingSkillPath for update: ${candidate.name}`,
          "error",
        );
        continue;
      }

      const existingContent = fs.readFileSync(existingPath, "utf-8");
      const { frontmatter, body } = extractFrontmatter(existingContent);
      const currentVersion =
        frontmatterGetScalar(frontmatter, "version") || "0.0.0";
      const bump = candidate.versionBump || "patch";
      const nextVersion = bumpVersion(currentVersion, bump);

      const updatedFrontmatter = frontmatter.match(/^version\s*:/m)
        ? frontmatter.replace(/^version\s*:\s*.+$/m, `version: ${nextVersion}`)
        : `${frontmatter}\nversion: ${nextVersion}`.trim();

      // Candidate content already includes frontmatter; prefer it, but ensure version is bumped.
      const candidateParsed = extractFrontmatter(skillContent);
      const candidateBody = candidateParsed.body || "";
      const updatedContent =
        `---\n${updatedFrontmatter}\n---\n\n${candidateBody}`.trimEnd() + "\n";

      // Use a temp file to compute diff reliably
      const tmpDir = fs.mkdtempSync(
        path.join(require("os").tmpdir(), "piception-update-"),
      );
      const tmpFile = path.join(tmpDir, "SKILL.md");
      fs.writeFileSync(tmpFile, updatedContent, "utf-8");
      let diffText = "";
      try {
        const diff = await execAsync(
          `git --no-pager diff --no-index -- "${existingPath}" "${tmpFile}" || true`,
          { timeout: 5000 },
        );
        diffText = diff.stdout || "";
      } finally {
        try {
          fs.rmSync(tmpDir, { recursive: true, force: true });
        } catch {}
      }

      if (diffText.trim()) {
        ctx.ui.notify(
          `Update diff for ${candidate.name} (${currentVersion} → ${nextVersion}):\n${diffText.split("\n").slice(0, 60).join("\n")}`,
          "info",
        );
      }

      const ok = await ctx.ui.confirm(
        `Update ${candidate.name}?`,
        `Bump: ${bump} (${currentVersion} → ${nextVersion})\nPath: ${existingPath}`,
      );
      if (!ok) {
        ctx.ui.notify(`Skipped update: ${candidate.name}`, "info");
        continue;
      }

      try {
        fs.writeFileSync(existingPath, updatedContent, "utf-8");
        success = true;
        location = existingPath;
      } catch (error) {
        console.error(`Failed to update skill at ${existingPath}:`, error);
      }

      if (!success) {
        ctx.ui.notify(`Failed to update: ${candidate.name}`, "error");
      }
    } else {
      // Create new skill
      success = createSkill(candidate.name, skillContent, userWide, ctx);
      location = userWide
        ? `~/.pi/agent/skills/${candidate.name}/SKILL.md`
        : `.pi/skills/${candidate.name}/SKILL.md`;
    }

    if (success) {
      const action = candidate.action === "update" ? "Updated" : "Created";
      ctx.ui.notify(`✓ ${action} skill at ${location}`, "info");
    } else {
      ctx.ui.notify(
        `Failed to ${candidate.action} skill: ${candidate.name}`,
        "error",
      );
    }
  }
}

// ============================================================================
// Interactive workflow helpers
// ============================================================================

async function promptUserReview(
  candidate: SkillCandidate,
  ctx: ExtensionContext,
): Promise<"approve" | "edit" | "skip"> {
  if (!ctx.hasUI) return "approve";

  const previewLines = candidate.content
    ? candidate.content.split("\n").slice(0, 10).join("\n")
    : "(no content provided by model)";

  const choice = await ctx.ui.select(`Skill: ${candidate.name}`, [
    "approve",
    "edit",
    "skip",
    // allow cancel = treat as skip
  ]);

  if (!choice) {
    ctx.ui.notify(`Cancelled: skipping ${candidate.name}`, "info");
    return "skip";
  }

  // Small preview to give context (notify is non-blocking)
  ctx.ui.notify(`Preview (${candidate.name}):\n${previewLines}`, "info");

  return choice as "approve" | "edit" | "skip";
}

async function chooseSkillLocation(
  ctx: ExtensionContext,
): Promise<"user" | "project"> {
  if (!ctx.hasUI) return "user";

  const choice = await ctx.ui.select("Install skill where?", [
    "user (~/.pi/agent/skills)",
    "project (.pi/skills)",
  ]);

  if (!choice) return "user";
  return choice.startsWith("project") ? "project" : "user";
}

async function editSkillContent(
  content: string,
  name: string,
): Promise<string> {
  // Prefer Pi's built-in multi-line editor when available (caller should gate via ctx.hasUI)
  // Fallback to external editor via $VISUAL/$EDITOR when no UI.
  // Note: We intentionally keep this function ctx-less for Step 5's requested signature.
  const envEditor = process.env.VISUAL || process.env.EDITOR;
  if (!envEditor) {
    // No external editor; return unchanged.
    return content;
  }

  // Temp file + external editor fallback
  const tmpDir = fs.mkdtempSync(
    path.join(require("os").tmpdir(), "piception-"),
  );
  const filePath = path.join(tmpDir, `${name}.md`);
  fs.writeFileSync(filePath, content, "utf-8");

  try {
    await execAsync(`${envEditor} "${filePath}"`, {
      timeout: 10 * 60 * 1000,
      env: { ...process.env },
    });
    return fs.readFileSync(filePath, "utf-8");
  } finally {
    try {
      fs.rmSync(tmpDir, { recursive: true, force: true });
    } catch {
      // best-effort cleanup
    }
  }
}

async function createSkillsHeadless(
  candidates: SkillCandidate[],
  ctx: ExtensionContext,
): Promise<void> {
  // Headless default: create/update all non-skipped candidates user-wide.
  const template = loadSkillTemplate();
  const now = new Date();
  const dateStr = now.toISOString().split("T")[0];

  for (const candidate of candidates) {
    if (candidate.action === "skip") continue;

    let skillContent = candidate.content || template;
    skillContent = skillContent.replace(/{{NAME}}/g, candidate.name);
    skillContent = skillContent.replace(
      /{{DESCRIPTION}}/g,
      candidate.description,
    );
    skillContent = skillContent.replace(/{{DATE}}/g, dateStr);
    skillContent = skillContent.replace(
      /{{TITLE}}/g,
      candidate.name
        .split("-")
        .filter((w) => w.length > 0)
        .map((w) => w[0].toUpperCase() + w.slice(1))
        .join(" "),
    );

    if (candidate.action === "update") {
      const existingPath = candidate.existingSkillPath;
      if (existingPath && fs.existsSync(existingPath)) {
        try {
          const existingContent = fs.readFileSync(existingPath, "utf-8");
          const { frontmatter } = extractFrontmatter(existingContent);
          const currentVersion =
            frontmatterGetScalar(frontmatter, "version") || "0.0.0";
          const bump = candidate.versionBump || "patch";
          const nextVersion = bumpVersion(currentVersion, bump);

          const updatedFrontmatter = frontmatter.match(/^version\s*:/m)
            ? frontmatter.replace(
                /^version\s*:\s*.+$/m,
                `version: ${nextVersion}`,
              )
            : `${frontmatter}\nversion: ${nextVersion}`.trim();

          const candidateParsed = extractFrontmatter(skillContent);
          const candidateBody = candidateParsed.body || "";
          const updatedContent =
            `---\n${updatedFrontmatter}\n---\n\n${candidateBody}`.trimEnd() +
            "\n";

          fs.writeFileSync(existingPath, updatedContent, "utf-8");
        } catch {
          // ignore
        }
      }
    } else {
      createSkill(candidate.name, skillContent, true, ctx);
    }
  }
}

// ============================================================================
// Extension Entry Point
// ============================================================================

export default function (pi: ExtensionAPI) {
  // Inject mandatory evaluation prompt on every agent start
  pi.on("before_agent_start", async (event, _ctx) => {
    const mandatoryPrompt = `
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🧠 MANDATORY SKILL EVALUATION REQUIRED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CRITICAL: After completing this user request, you MUST evaluate whether
it produced extractable knowledge and, if so, run /piception.

EVALUATION PROTOCOL (NON-NEGOTIABLE):

1. COMPLETE the user's request first
2. EVALUATE: Ask yourself:
   - Did this require non-obvious investigation or debugging?
   - Was the solution something that would help in future similar situations?
   - Did I discover something not immediately obvious from documentation?

3. IF YES to any question above:
   ACTIVATE: Run /piception NOW to extract the knowledge

4. IF NO to all questions:
   SKIP: No skill extraction needed

This is NOT optional. Failing to evaluate means valuable knowledge is lost.
The piception extension will decide whether to actually create a new
skill based on its quality criteria.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`;

    return {
      systemPrompt: event.systemPrompt + mandatoryPrompt,
    };
  });

  // Manual extraction command
  pi.registerCommand("piception", {
    description: "Review session and extract reusable skills",
    handler: async (args, ctx) => {
      try {
        const branch = ctx.sessionManager.getBranch();
        const conversationText = buildConversationText(branch);

        if (!conversationText.trim()) {
          if (ctx.hasUI) {
            ctx.ui.notify("No conversation to analyze", "warning");
          }
          return;
        }

        if (ctx.hasUI) {
          ctx.ui.notify("Analyzing session...", "info");
        }

        const candidates = await identifySkillCandidates(conversationText, ctx);

        if (!candidates || candidates.length === 0) {
          if (ctx.hasUI) {
            ctx.ui.notify(
              "No extractable skills found in this session",
              "info",
            );
          }
          return;
        }

        await createSkillsInteractively(candidates, ctx);
      } catch (error) {
        console.error("Error in piception command handler:", error);
        if (ctx.hasUI) {
          ctx.ui.notify(
            "Failed to execute piception command. Check logs for details.",
            "error",
          );
        }
      }
    },
  });
}
