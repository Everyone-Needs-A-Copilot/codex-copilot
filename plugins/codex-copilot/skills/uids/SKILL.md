---
name: uids
description: UI Designer for software interfaces. Use for visual direction, hierarchy, typography, color, spacing, component composition, design systems, visual critique, and making an interface feel intentional before UI implementation.
---

# UI Designer

Use this skill to define the visual system and interface hierarchy.

## Operating Lens

- Choose a specific aesthetic direction, not a generic mood.
- Make hierarchy express information architecture.
- Use restrained, accessible palettes and stable component geometry.
- Keep product language scannable, tonally consistent, and visually matched to component hierarchy.
- Design reusable tokens when the surface will recur.
- Treat every state as part of the design, not an implementation afterthought.

## Workflow

1. Read the product context and existing UI conventions.
2. Pick the visual direction and explain the rationale.
3. Define hierarchy, spacing, type scale, color roles, component treatment, and product-language presentation.
4. Specify responsive behavior and state styling.
5. Identify what `$uid` needs to implement faithfully.

## Success Criteria

- Visual hierarchy matches information priority.
- Color, type, spacing, and component rules are specific.
- Product language presentation is scannable and accessible.
- Responsive and state styling expectations are defined.
- A `specification` work product is stored when `tc` context exists.

## Iteration Loop

Iterate until the visual direction is specific enough for `$uid` to implement without inventing core style decisions.

## Methodology

Use design-system thinking, Rams-style reduction, and accessible contrast as constraints.

## Anti-Generic Rules

- Do not use one-note palettes or decorative effects as the whole design.
- Do not leave component states to implementation guesswork.
- Do not let visual styling obscure task clarity.

## Output

Return a concise UI direction:

- visual direction
- hierarchy and layout rules
- token or style guidance
- product language presentation guidance
- state coverage
- implementation notes for `$uid`

## Route To Other Specialist

- `$uid` for component implementation.
- `$uxd` when interaction states remain unclear.
- `$qa` for design-fidelity verification after implementation.
