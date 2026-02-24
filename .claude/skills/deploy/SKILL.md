---
name: deploy
description: Use when ready to deploy changes - creates PR, pushes, and monitors CI build and TestFlight deployment until complete
---

# Deploy to TestFlight

Create a PR, push it, and monitor the full CI pipeline through TestFlight deployment.

## Workflow

### 1. Prepare Branch & PR

```
# Check current state
git status
git diff
git log --oneline -5

# Create branch if on main
git checkout -b <descriptive-branch-name>

# Stage and commit (skip .claude/settings.local.json)
git add <files>
git commit -m "message

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"

# Push and create PR
git push -u origin <branch-name>
gh pr create --title "PR title" --body "$(cat <<'EOF'
## Summary
- Change description

## Test plan
- [ ] Build succeeds
- [ ] TestFlight deployment completes

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

### 2. Merge PR

After PR is created, merge it to trigger the TestFlight workflow:

```bash
gh pr merge <pr-number> --squash --delete-branch
```

### 3. Monitor CI Build

The `Deploy to TestFlight` workflow triggers on push to main. Poll until complete:

```bash
# Wait for workflow run to appear (may take a few seconds)
gh run list --workflow=testflight.yml --limit=1 --json databaseId,status,conclusion

# Watch the run (polls automatically)
gh run watch <run-id>
```

**Poll every 30 seconds** using `gh run view <run-id> --json status,conclusion` if `gh run watch` is unavailable.

### 4. Report Result

**On success:**
> Deploy complete. PR #<number> merged and TestFlight build deployed successfully.
> Workflow run: <url>

**On failure:**
> Deploy failed at step: <step-name>
> Error: <error summary>
> Workflow run: <url>

If failed, fetch logs with:
```bash
gh run view <run-id> --log-failed
```

## Key Details

- **Workflow file**: `.github/workflows/testflight.yml`
- **Trigger**: Push to `main` or `preview/**`
- **Runner**: `macos-14`, timeout 30 min
- **Pipeline**: Xcode build → Fastlane beta → TestFlight upload
- **Timeout**: If CI hasn't completed in 35 minutes, report as timed out
