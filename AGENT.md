# AGENT.md

This file gives project-specific instructions to coding agents working in this repository.

## Project Status

Cat Chaos is a spec-first Godot project. The repository currently contains design and planning documents, not a playable implementation yet.

Core MVP:

- `1` cat
- `1` room
- `3` visible stats: `fullness`, `happiness`, `calmness`
- `2` player actions: `Feed`, `Pet`
- fixed deterministic loop: `DAY (10s) -> EVENING (15s) -> NIGHT (5s)`

Primary goal: build a small, deterministic, readable pet-care game with clear cause and effect.

## Document Precedence

Treat the docs as a contract. When they conflict, resolve work in this order:

1. `docs/spec.md`
   Gameplay source of truth: rules, timings, state shape, update order, acceptance tests.
2. `docs/architecture.md`
   Implementation structure: scene boundaries, ownership, signals, folder layout, anti-patterns.
3. `docs/art_direction.md`
   Visual, UI, and audio direction for MVP assets and presentation.
4. `docs/release-checklist.md`
   Verification gates, known cross-doc issues, and release readiness checks.

`README.md` is a concise project summary and should stay aligned with the docs above.

## Non-Negotiable Constraints

- `GameManager` is the sole writer to authoritative gameplay state.
- `UI`, `Cat`, `Player`, and `Environment` must not mutate `GameState` directly.
- Use signals for player intents and domain events.
- Keep gameplay deterministic from initial seed plus input sequence.
- Run simulation on a `1` second tick. Do not put gameplay state mutation in `_process()`.
- Keep balance values in data/resources, not duplicated magic numbers in scripts.
- Clamp all stats to `0..100`.
- `NIGHT` is read-only.
- Do not add out-of-scope MVP systems such as inventory, economy, progression, multiple pets, or room navigation unless the docs are explicitly expanded first.

## Gameplay Contract

Authoritative state from the spec:

- `phase`
- `phase_time_remaining`
- `fullness`
- `happiness`
- `calmness`
- `active_request`
- `cycle_index`
- `rng_state`

Deterministic tick order from `docs/spec.md` must stay fixed:

1. Apply player input for the current tick.
2. Apply passive stat rules for the current phase.
3. Update the active request timer and resolve completion or timeout.
4. Decrement `phase_time_remaining`.
5. Perform phase transition if the timer reached `0`.
6. If a new evening request window starts, spawn the next request.

If implementation changes this order, update the spec and tests in the same change.

## Known Open Decisions

These are intentionally unresolved in the docs and must not be handled casually:

- `active_request` is `null` in the spec and `{}` / empty `Dictionary` in the architecture.
- Matched-request rewards are ambiguous: the current wording can imply double reward on matching actions.

If work requires resolving either issue:

- choose one canonical behavior
- update `docs/spec.md`, `docs/architecture.md`, and `docs/release-checklist.md` together
- add or update tests so the behavior is locked
- mention the decision clearly in the change summary

Do not silently implement one interpretation while leaving the docs inconsistent.

## Expected Architecture

Top-level scene tree:

```text
Main
├── GameManager
├── UI
├── Cat
├── Player
└── Environment
```

Responsibility split:

- `Main`: composition root and signal wiring
- `GameManager`: state, ticks, transitions, request logic, sleep evaluation
- `UI`: render state, timers, buttons, prompts, result panels
- `Cat`: animation, reactions, audio hooks only
- `Player`: input to `feed` / `pet` intents
- `Environment`: phase-based room visuals and mood

Preferred repository layout:

```text
/docs
/scenes
/scripts
/systems
/ui
/data
/tests
```

## Implementation Guidance

When building the project, prefer this sequence:

1. Create the Godot project and main scene composition.
2. Add `GameState` and `GameConfig` resources or equivalents.
3. Implement `GameManager` and the deterministic tick/update flow.
4. Implement request generation, request resolution, and sleep evaluation.
5. Add `UI` for stats, timers, request prompts, and sleep result.
6. Add `Cat`, `Player`, and `Environment` as presentation/input layers around the simulation.
7. Add deterministic unit and integration tests.

Keep systems small and explicit. If helper systems are added under `/systems`, they should support `GameManager`, not compete with it for state ownership.

## UI, Art, and Audio Boundaries

The MVP should look and sound cozy, readable, and intentionally scoped:

- cozy stylized 2D pixel art
- single intimate room
- fixed side-view or light `3/4` view
- strong phase readability across `DAY`, `EVENING`, and `NIGHT`
- request prompts, timers, and sleep result must be visually obvious
- controls must be clearly disabled or ignored during `NIGHT`

Avoid visuals that imply systems the game does not have, such as shops, inventory, quest logs, or multiple rooms.

## Testing and Verification

Minimum verification expectations:

- unit tests for the acceptance criteria in `docs/spec.md`
- tests for stat clamping
- tests for deterministic request generation from a fixed seed
- tests for update-order correctness
- tests for phase transitions and `cycle_index`
- at least one deterministic full-cycle test: `DAY -> EVENING -> NIGHT -> DAY`

Before calling work complete, check against `docs/release-checklist.md`.

## Agent Workflow

When making changes:

- read the relevant doc sections first
- preserve the spec as the gameplay contract
- preserve architecture ownership boundaries
- keep presentation aligned with the art direction
- update docs when implementation decisions materially change behavior or structure
- prefer small, reviewable changes with matching tests

If a task is ambiguous and the answer is not already defined in the docs, either resolve it across all affected docs and tests in one change or stop and ask for clarification.
