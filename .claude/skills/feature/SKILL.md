---
name: feature
description: Full feature development with extensive planning, exploration, and design
---

# Feature Development Mode

You are in **feature development mode**. Follow this comprehensive workflow with extensive planning before implementation.

## Workflow

### Phase 0: Branch Setup

**CRITICAL**: Before starting, create a preview branch for TestFlight deployment:
   - Create branch with pattern: `preview/feature-name` (e.g., `preview/export-history`)
   - This will auto-deploy to TestFlight "Feature Preview" group on push
   - All development happens on this branch

### Phase 1: Research & Exploration (30-40% of effort)

1. **Use Explore agents extensively**
   - Spawn Explore agent to understand codebase structure
   - Identify all affected components and files
   - Research similar existing features
   - Understand data flow and architecture

2. **Create detailed specification**
   - What: Clear description of the feature
   - Why: Business/user value
   - How: Technical approach
   - Where: Affected files and components
   - Dependencies: External libraries or APIs needed
   - Edge cases: Scenarios to handle

### Phase 2: Design & Planning

3. **Design the implementation**
   - Propose the technical approach
   - Discuss architectural decisions
   - Consider multiple alternatives
   - Identify tradeoffs (simplicity vs flexibility, performance, maintainability)
   - Break down into logical steps

4. **Get user feedback**
   - Present the plan clearly
   - Ask for approval or adjustments
   - Use AskUserQuestion for key decisions
   - **CRITICAL**: Do not start implementation until plan is approved

### Phase 3: Implementation

5. **Build incrementally with continuous verification**
   - Create TodoWrite list for tracking implementation steps
   - Implement in logical chunks
   - **Build and run in simulator after each significant change** (per CLAUDE.md)
   - Test each component as you go
   - Follow existing code patterns and conventions
   - Commit regularly to preview branch
   - Push to trigger TestFlight builds for device testing

6. **Comprehensive testing**
   - Unit tests where applicable
   - Integration testing
   - Edge case handling
   - Build and verify in simulator continuously
   - Test on actual device via TestFlight preview builds

### Phase 4: Documentation & Review

7. **Document the changes**
   - Update relevant documentation
   - Add code comments for complex logic
   - Update README if needed

8. **Create thorough PR from preview branch to main**
   - Push final changes to preview branch
   - Create PR from `preview/feature-name` → `main`
   - Detailed PR description with context
   - Explain design decisions
   - Include test plan and TestFlight testing notes
   - Note any follow-up work needed

## Guidelines

- **Always use TodoWrite** - Track all implementation steps
- **Use multiple Explore agents** - Don't skip thorough codebase research
- **Plan before implementing** - Never jump straight to code
- **Deep reasoning** - Think through implications and tradeoffs
- **Ask questions** - Use AskUserQuestion for clarification
- **Comprehensive scope** - Consider related improvements and documentation
- **Quality over speed** - Take time to do it right

## Example

User: "Feature: Add ability to export fasting history to CSV and PDF"

Response:
1. Create preview branch: `preview/export-history`
2. Use Explore agent to find existing export/sharing functionality
3. Use Explore agent to understand fasting history data model
4. Research iOS libraries for CSV/PDF generation
5. Create detailed plan:
   - Data extraction from CoreData/storage
   - CSV formatting logic
   - PDF generation with formatting
   - UI for triggering export
   - Share sheet integration
   - Error handling
6. Present plan with alternatives (e.g., native PDF vs third-party library)
7. Get user approval
8. Create TodoWrite with ~10-15 implementation steps
9. Implement incrementally, building and testing in simulator after each chunk
10. Commit and push to preview branch regularly
11. Test on device via TestFlight preview builds
12. Update documentation
13. Create comprehensive PR from preview/export-history → main
