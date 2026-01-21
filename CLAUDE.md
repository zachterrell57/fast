# Fast

Fasting tracker iOS app.

## Workflow Modes

**CRITICAL**: Detect workflow mode from message content and **IMMEDIATELY invoke the appropriate Skill tool** as your FIRST action:

### Bug Fix Mode
**Trigger**: Message contains the word "bug" (case-insensitive) OR starts with "Fix:", "Hotfix:", or "Quick fix:"

**Action**: **IMMEDIATELY invoke** `Skill tool: skill="bug-fix"`

### Feature Development Mode
**Trigger**: Message starts with "Feature:", "Implement:", "Add:", or "Plan and implement:"

**Action**: **IMMEDIATELY invoke** `Skill tool: skill="feature"`

### Default Behavior
If no prefix is detected, ask the user which mode they want, or infer from context (simple fixes = bug mode, new functionality = feature mode).

See `.claude/skills/` for detailed workflow definitions.

## Workflow

- After completing UI changes, build and run in the simulator to reflect changes
