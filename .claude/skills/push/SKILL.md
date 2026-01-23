---
name: push
description: Add, commit, and push all changes to main
---

# Push to Main

Quick workflow to stage all changes, commit with an auto-generated message, and push to main.

## Workflow

1. **Check status**
   - Run `git status` to see all changes
   - Run `git diff` to understand what changed

2. **Stage all changes**
   - Add all modified and untracked files
   - Skip files that should typically be ignored (credentials, secrets)

3. **Create commit**
   - Generate a concise commit message summarizing the changes
   - Include Co-Authored-By trailer
   - Use HEREDOC format for the commit message

4. **Push to main**
   - Push directly to origin/main

## Guidelines

- **No confirmation needed** - Execute immediately
- **Auto-generate message** - Create appropriate commit message from the diff
- **Direct to main** - No branch creation, push straight to main
- **Skip local settings** - Don't commit .claude/settings.local.json unless explicitly requested
