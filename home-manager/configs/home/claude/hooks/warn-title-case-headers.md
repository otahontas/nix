---
name: warn-title-case-headers
enabled: true
event: all
pattern: '^#+\s+(?:[A-Z][a-z]*\s+)+[A-Z][a-z]+'
action: warn
---

⚠️ **Title case header detected**

You're using title case in a header (like "Next Steps" instead of "Next steps").

Your CLAUDE.md says: "Headers: always use sentence case"

Examples:
- ❌ "Next Steps" → ✅ "Next steps"
- ❌ "Plan Overview" → ✅ "Plan overview"
- ❌ "API Key Setup" → ✅ "API key setup"
- ❌ "The Next Steps" → ✅ "The next steps"

Please rewrite the header in sentence case before sending.
