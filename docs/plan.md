# PLAN.md

This implementation plan is derived from:

- `docs/spec.md`
- `docs/architecture.md`
- `docs/art_direction.md`
- `docs/release-checklist.md`

The intent is to move from a documentation-only repository to a playable MVP without violating the spec, architecture boundaries, or release criteria.

## 1. Start From the Locked Gameplay Contract

The previously open cross-doc decisions are now fixed:

- `active_request` is `null` when no request is active
- matching a request applies the triggering action's normal stat gain exactly once
- request completion adds no extra stat reward beyond avoiding failure

Implementation and tests should treat these rules as part of the baseline contract.

## 2. Bootstrap the Godot Project

Create the base project structure described in `docs/architecture.md`:

```text
/docs
/scenes
/scripts
/systems
/ui
/data
/tests
```

Initial setup should include:

- `project.godot`
- a top-level `Main` scene
- placeholder scenes/scripts for `GameManager`, `UI`, `Cat`, `Player`, and `Environment`
- base input mappings needed for `Feed` and `Pet`

The repository should become runnable as a minimal Godot project as early as possible.

## 3. Implement the Authoritative Gameplay Core

Build the simulation first, before presentation polish.

Core work:

- define `GameState`
- define `GameConfig` as externalized tunable data
- implement `GameManager` as the sole writer to gameplay state
- add a `1` second timer-driven tick loop
- implement fixed phase durations for `DAY`, `EVENING`, and `NIGHT`
- clamp all stats to `0..100`
- enforce `NIGHT` as read-only

All game logic must remain deterministic from initial seed plus input sequence.

## 4. Implement Deterministic Rule Processing

Implement the tick update order from the spec exactly:

1. apply player input for the current tick
2. apply passive stat rules for the current phase
3. update the active request timer and resolve completion or timeout
4. decrement `phase_time_remaining`
5. perform phase transition if the timer reached `0`
6. if a new evening request window starts, spawn the next request

Rules to implement:

- `DAY` passive changes
- `EVENING` passive changes
- no passive changes during `NIGHT`
- exactly `3` request windows during each `EVENING`
- seeded request generation from `FOOD` and `ATTENTION`
- request completion and failure handling
- sleep evaluation exactly once when `NIGHT` begins

This step should produce a simulation that can already be tested without finished art.

## 5. Add Signal-Driven Scene Integration

Follow the architecture ownership model:

- `Main` composes and wires the top-level scene tree
- `UI` emits player-facing intents
- `Player` converts input into `feed` / `pet` intents
- `Cat` reacts to events only
- `Environment` reacts to phase and outcome only

Rules:

- `GameManager` stays the only writer to `GameState`
- presentation nodes consume state and signals but do not mutate gameplay state
- avoid deep node-path coupling
- do not move gameplay mutation into `_process()`, UI handlers, or animation logic

## 6. Build the MVP UI

Implement the minimum readable interface required by the spec and art direction.

Always-visible UI:

- current phase
- phase timer
- `fullness`
- `happiness`
- `calmness`
- `Feed` action
- `Pet` action

Conditional UI:

- active request during `EVENING`
- request countdown during `EVENING`
- sleep result during `NIGHT`

Interaction rules:

- action controls work during `DAY` and `EVENING`
- action controls are disabled or ignored during `NIGHT`
- feedback must read clearly on a `1` second gameplay tick

## 7. Add Cat and Environment Presentation

Bring in the MVP presentation layer from `docs/art_direction.md` without expanding scope.

Visual targets:

- cozy stylized 2D pixel-art presentation
- one intimate room
- fixed side-view or light `3/4` view
- clear lighting and mood differences across `DAY`, `EVENING`, and `NIGHT`
- readable request, success, failure, and sleep-result feedback

Cat presentation scope:

- idle
- request reaction
- satisfied reaction
- failed-request reaction
- sleep pose

Keep art and audio choices aligned with the MVP and avoid implying systems that do not exist.

## 8. Add Automated Test Coverage

Create tests that enforce the gameplay contract.

Unit tests should cover:

- sleep outcome thresholds
- request generation count in one evening
- request completion behavior
- request failure penalties
- stat clamping at lower and upper bounds
- deterministic request generation from a fixed seed
- fixed tick update order
- phase transitions and `cycle_index`

Integration coverage should include:

- at least one full deterministic `DAY -> EVENING -> NIGHT -> DAY` cycle
- one manual or scripted verification that exactly `3` requests occur in an evening

## 9. Validate Against the Release Checklist

Before considering the MVP complete, verify:

- scene composition matches the architecture
- ownership boundaries are preserved
- signals are used for intents and domain events
- tunable values live in data/resources
- the current phase, timers, stats, requests, and sleep result are visible
- determinism holds from seed plus input sequence
- the Godot project opens without broken scenes or missing resources
- export and packaging prerequisites are in place

Any divergence between implementation and docs must be corrected in the same pass, either by changing code or updating the docs.

## 10. Suggested Delivery Order

Recommended milestone sequence:

1. start from the aligned gameplay contract
2. Godot project bootstrap
3. gameplay core and deterministic tick
4. requests and sleep evaluation
5. signal wiring and top-level scene composition
6. UI and input flow
7. cat/environment presentation
8. automated tests
9. release-checklist verification

This order keeps the hardest correctness risks in the simulation layer, where they can be tested before presentation work adds noise.
