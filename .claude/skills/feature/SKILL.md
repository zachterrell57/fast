---
name: feature
description: Full feature development with extensive planning, exploration, and design
---

# Feature Development Mode

You are in **feature development mode**. Follow this comprehensive workflow with extensive planning before implementation.

## Workflow

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

5. **Build incrementally**
   - Create TodoWrite list for tracking implementation steps
   - Implement in logical chunks
   - Test each component as you go
   - Follow existing code patterns and conventions

6. **Comprehensive testing**
   - Unit tests where applicable
   - Integration testing
   - Edge case handling
   - For UI: Build and run in simulator (per CLAUDE.md)

### Phase 4: Documentation & Review

7. **Document the changes**
   - Update relevant documentation
   - Add code comments for complex logic
   - Update README if needed

8. **Create thorough PR**
   - Detailed PR description with context
   - Explain design decisions
   - Include test plan
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
1. Use Explore agent to find existing export/sharing functionality
2. Use Explore agent to understand fasting history data model
3. Research iOS libraries for CSV/PDF generation
4. Create detailed plan:
   - Data extraction from CoreData/storage
   - CSV formatting logic
   - PDF generation with formatting
   - UI for triggering export
   - Share sheet integration
   - Error handling
5. Present plan with alternatives (e.g., native PDF vs third-party library)
6. Get user approval
7. Create TodoWrite with ~10-15 implementation steps
8. Implement incrementally
9. Test thoroughly
10. Update documentation
11. Create comprehensive PR
