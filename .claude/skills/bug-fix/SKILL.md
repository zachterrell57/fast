---
name: bug-fix
description: Quick bug fix workflow - diagnose, fix, test, commit
---

# Bug Fix Mode

You are in **quick-fix mode**. Follow this streamlined workflow:

## Workflow

1. **Understand the bug**
   - Read error messages and stack traces
   - Identify the root cause quickly
   - Read only the relevant files

2. **Minimal implementation**
   - Make the smallest fix that resolves the issue
   - Avoid refactoring or "improving" surrounding code
   - Stay focused on the specific bug

3. **Test the fix**
   - Run relevant tests to verify the fix works
   - Build the app if it's a UI change (per CLAUDE.md)
   - Ensure no regressions

4. **Commit and push to main**
   - Create a clear, concise commit message
   - Focus on what was fixed and why
   - Push directly to main (triggers TestFlight deployment automatically)

## Guidelines

- **Skip extensive planning** - No need for detailed plans or specifications
- **No TodoWrite** - Don't create todo lists for simple fixes
- **Direct action** - Move quickly from diagnosis to implementation
- **Minimal scope** - Only touch what's necessary to fix the bug
- **No documentation updates** - Unless the bug is in documentation itself

## Example

User: "Bug fix: App crashes when tapping empty fasting list"

Response:
1. Read the relevant view controller/component
2. Identify the nil/null reference issue
3. Add proper nil check or empty state handling
4. Build and run in simulator to verify
5. Commit with message like "Fix crash on empty fasting list"
6. Push to main (auto-deploys to TestFlight)
