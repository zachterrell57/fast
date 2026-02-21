---
name: run-simulator
description: Build and run the app in the iOS simulator
---

# Run Simulator

Build and launch the app in the iOS simulator.

## Workflow

1. **Open simulator**
   - Use `mcp__xcodebuildmcp__open_sim` to open the Simulator app

2. **Boot device**
   - Use `mcp__xcodebuildmcp__boot_sim` to boot iPhone 16 Pro Max with iOS 26

3. **Build and run**
   - Use `mcp__xcodebuildmcp__build_run_sim` to build and run the Fast scheme on the booted simulator

## Guidelines

- **No confirmation needed** - Execute immediately
- **Always use iPhone 16 Pro Max** with iOS 26
- **Report errors clearly** - If the build fails, show the error output
