# Codex Start Here — HRV-C

## What this package does

This package transfers the product, UX and design context into repository-native files that Codex can read without relying on chat history.

Codex should begin by reading `AGENTS.md`, then the documents listed there. The repository-level `AGENTS.md` contains permanent rules; task-specific work belongs in `tasks/`.

## First command / prompt

Use this as the first Codex task:

> Read AGENTS.md and every source-of-truth document it references. Audit the repository against tasks/M1_M3_IMPLEMENTATION.md. Do not change detector mathematics. Produce a short gap report, then implement only M1 in a new branch. Run pytest and update docs/DECISIONS.md for any new product decision. Clearly separate completed work, uncompiled Swift scaffolds, and items blocked by macOS/Xcode.

## Recommended branch

`feature/m1-state-model`

## Expected first deliverable

- Product state contract committed to the repository.
- Canonical Hebrew copy documented.
- Internal detector states mapped to presentation states.
- Tests for any pure mapping logic introduced.
- No UI implementation claims without Xcode validation.

## Figma links

- Master creation plan: https://www.figma.com/design/hlCzE7OlX9yaZa7s5UJyhL?node-id=96-2
- State model and canonical copy: https://www.figma.com/design/hlCzE7OlX9yaZa7s5UJyhL?node-id=103-2
- High-fidelity iOS page: https://www.figma.com/design/hlCzE7OlX9yaZa7s5UJyhL?node-id=42-2
- High-fidelity watchOS page: https://www.figma.com/design/hlCzE7OlX9yaZa7s5UJyhL?node-id=42-3
- Prototype: https://www.figma.com/design/hlCzE7OlX9yaZa7s5UJyhL?node-id=52-2
- Developer handoff: https://www.figma.com/design/hlCzE7OlX9yaZa7s5UJyhL?node-id=58-2
