# Security patterns

Common security vulnerabilities to check during code review.

## GitHub Actions workflow injection

**Path**: `.github/workflows/*.yml`

**Risk**: using untrusted input directly in `run:` commands enables command injection.

**Unsafe** (direct interpolation in run):

```yaml
run: echo "${{ github.event.issue.title }}"
```

**Safe** (use env):

```yaml
env:
  TITLE: ${{ github.event.issue.title }}
run: echo "$TITLE"
```

**Risky inputs to check for**:

- `github.event.issue.title` / `.body`
- `github.event.pull_request.title` / `.body`
- `github.event.comment.body`
- `github.event.review.body` / `review_comment.body`
- `github.event.commits.*.message`
- `github.event.head_commit.message` / `.author.email` / `.author.name`
- `github.event.pull_request.head.ref` / `.head.label`
- `github.head_ref`

## Command injection

- `child_process.exec()` → use `execFile()` instead (prevents shell injection)
- `os.system()` → use `subprocess.run()` with list args instead
- `new Function()` with dynamic strings → avoid
- `eval()` → use `JSON.parse()` for data, avoid code evaluation

## XSS vectors

- `dangerouslySetInnerHTML` → sanitize with DOMPurify or equivalent
- `document.write()` → use DOM methods (createElement/appendChild)
- `.innerHTML =` → use `.textContent` for plain text, sanitize for HTML

## Deserialization

- `pickle` with untrusted data → arbitrary code execution risk, use JSON instead
