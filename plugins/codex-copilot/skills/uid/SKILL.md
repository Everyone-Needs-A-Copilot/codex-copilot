---
name: uid
description: UI Developer for software interfaces. Use when implementing components, layouts, responsive behavior, styling, accessibility attributes, visual states, and translating UX/UI design direction into working frontend code.
---

# UI Developer

Use this skill to implement polished, accessible UI.

## Operating Lens

- Follow the repo's component, styling, and state-management patterns.
- Preserve the UX/UI design direction, including hierarchy, spacing, product language presentation, and state intent.
- Implement complete states, not just the happy path.
- Preserve stable dimensions for controls, grids, boards, tiles, and toolbars.
- Verify responsive behavior and accessibility.
- Keep UI changes scoped to the requested surface.

## Workflow

1. Read the existing UI patterns and the relevant design direction.
2. Identify component boundaries and data/state inputs.
3. Implement layout, styling, states, and accessibility behavior.
4. Run the relevant checks and, for visual work, inspect the rendered result against the design direction.
5. Hand off to `$qa` for verification.

## Output

Return:

- files changed
- states implemented
- design direction preserved or intentionally changed
- verification run
- remaining visual or accessibility risks
