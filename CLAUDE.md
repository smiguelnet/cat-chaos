# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Cat Chaos is a small 2D pet-care game for Godot. The project is currently **spec-first**: comprehensive documentation exists but the game implementation does not yet exist in the repository.

**Core concept**: Player manages one cat through a deterministic day loop (DAY → EVENING → NIGHT), trying to reach bedtime with the cat fed, happy, and calm enough for peaceful sleep.

## Documentation Hierarchy

The documentation forms a contract system. When implementing:

1. **docs/spec.md** is the gameplay source of truth
   - All game rules, stats, timing, and acceptance criteria
   - TypeScript-style state definitions for clarity
   - Fixed deterministic update order

2. **docs/architecture.md** defines implementation structure
   - Scene-first, signal-driven Godot patterns
   - Strict state ownership rules (GameManager is the sole writer to GameState)
   - Component responsibilities and anti-patterns to avoid

3. **docs/art_direction.md** guides visual and audio work
   - Cozy stylized 2D pixel art direction
   - Phase presentation requirements
   - Asset scope and approval criteria

4. **docs/release-checklist.md** lists verification gates
   - Pre-release validation checklist
   - Known open issues to resolve before release

## Resolved Gameplay Decisions

These decisions are now fixed across the docs:

- **active_request representation**: use `null` when no request is active.
- **Matched-request rewards**: matching a request applies the triggering action's normal stat gain exactly once. Request completion adds no extra stat bonus.

## Architecture Constraints

### State Ownership Rules

- **GameManager** is the ONLY writer to GameState
- All other nodes (UI, Cat, Player, Environment) are readers only
- Player actions and UI interactions emit intent signals, not direct mutations
- GameManager validates, mutates state, clamps values, then emits domain events

### Communication Patterns

- Use Godot signals for domain events and player intents
- Connect signals once in Main during `_ready()`
- Avoid `get_node()` lookups scattered through gameplay code
- Prefer one-way flow: intent in → state/event out

### Deterministic Gameplay

- All game logic runs on 1-second tick (Timer-driven, not `_process()`)
- No frame-rate dependent behavior
- Seedable RNG for request generation
- All outcomes must be reproducible from initial seed + input sequence
- Fixed update order per spec section 11

### Configuration

- Balance values live in data assets (Resource files), not hardcoded in scripts
- Use `GameConfig` Resource with @export vars for all tunable values
- No duplicated magic numbers across scripts

## Scene Structure

```
Main
├── GameManager (owns GameState, runs tick logic, emits events)
├── UI (renders state, emits player intent signals)
├── Cat (animation/reactions only, no state mutation)
├── Player (input → intent translation)
└── Environment (phase-based visuals)
```

## Anti-Patterns to Avoid

- God object GameManager that also handles animation, UI, and rendering
- Direct node path coupling (deep `get_node("../../...")` chains)
- Autoloading gameplay state
- UI or Cat nodes mutating GameState directly
- Using `_process()` for simulation timing
- Duplicating balance values across multiple scripts
- Implementing game rules in presentation layers

## Planned Folder Structure

When implementation begins:

```
/docs          - specification and design docs
/scenes        - .tscn composition files
/scripts       - .gd behavior scripts
/systems       - pure gameplay logic helpers
/ui            - UI scenes and scripts
/data          - Resource files for config and balance
/tests         - unit and integration tests
```

## Development Workflow

1. Implement against spec.md gameplay rules
2. Follow architecture.md ownership boundaries and signal patterns
3. Keep art work aligned with art_direction.md
4. Verify against release-checklist.md before release
5. Update docs if implementation requires spec changes

## Design Principles

- **Clarity over depth**: Easy to understand in first minute
- **Deterministic**: Fully reproducible from seed + input
- **Small scope**: 1 cat, 1 room, 3 stats, 2 actions
- **Readable feedback**: Clear cause-and-effect at 1-second tick rate
- **Scene-first**: Composition over inheritance, signals over coupling

## Godot-Specific Notes

- Target tick rate: exactly 1 update per second
- Stats are clamped to 0..100 (integers)
- Phase durations: DAY=10s, EVENING=15s, NIGHT=5s
- Player input accepted only during DAY and EVENING (NIGHT is read-only)
- Request windows: exactly 3 per EVENING, 5 seconds each
- Sleep evaluation: single check when NIGHT begins (fullness/happiness/calmness all ≥70 = Good Sleep)

## Testing Requirements

When tests are written:

- Unit tests must cover acceptance tests from spec.md section 13
- Tests must verify deterministic behavior from fixed seed
- Tests must validate stat clamping at bounds
- Tests must verify fixed update order
- Integration tests must cover full cycle: DAY → EVENING → NIGHT → DAY

## Contributing Guidelines

- Preserve the spec as the gameplay source of truth
- Maintain ownership boundaries from architecture.md
- Do not invent systems outside MVP scope (no inventory, progression, economy, multiple pets)
- Resolve spec/architecture inconsistencies before implementing ambiguous areas
- Keep CLAUDE.md updated if core patterns or workflow change
