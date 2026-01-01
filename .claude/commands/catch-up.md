Analyze the current branch's changes to help resume work:

1. Check if `docs/plans/` exists and read any implementation plans related to current work
2. Find the default branch (try: main, master, development, develop in that order)
3. Get current branch name
4. Show summary: `git diff --stat <default-branch>...HEAD`
5. Show actual changes: `git diff <default-branch>...HEAD`
6. Provide 3-4 line summary combining:
   - What the plan says (if plan exists)
   - What's been implemented based on diff
   - What appears to be left

Keep summary concise - just key status. Don't elaborate unless asked.
