# Fast

Fasting tracker iOS app.

## Workflow Modes

**CRITICAL**: Detect workflow mode from message prefix and follow the appropriate workflow:

### Bug Fix Mode
**Trigger**: Message starts with any of:
- "Bug fix:"
- "Fix:"
- "Hotfix:"
- "Quick fix:"

**Action**: Follow the `/bug-fix` skill workflow:
- Jump directly to implementation
- No extensive planning or TodoWrite
- No Explore agents
- Quick diagnosis → minimal fix → test → commit
- Focus and speed over comprehensive analysis

### Feature Development Mode
**Trigger**: Message starts with any of:
- "Feature:"
- "Implement:"
- "Add:"
- "Plan and implement:"

**Action**: Follow the `/feature` skill workflow:
- **REQUIRED**: Extensive planning before any implementation
- Use multiple Explore agents to scan the codebase
- Create detailed specification/PRD
- Use TodoWrite to track all steps
- Present plan and get approval before implementing
- Deep reasoning about tradeoffs and alternatives
- Comprehensive testing and documentation

### Default Behavior
If no prefix is detected, ask the user which mode they want, or infer from context (simple fixes = bug mode, new functionality = feature mode).

## Workflow

- After completing UI changes, build and run in the simulator to reflect changes
