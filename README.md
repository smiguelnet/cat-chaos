# Cat Chaos

Cat Chaos is a small 2D pet-care game built around a deterministic day loop. The player manages one cat through `DAY`, `EVENING`, and `NIGHT`, trying to reach bedtime with the cat fed, happy, and calm enough for a peaceful sleep.

The repository now contains a playable Godot MVP scaffold, the deterministic gameplay implementation, and a custom headless test runner alongside the original planning documents.

## Overview

The MVP is intentionally narrow:

- `1` cat
- `1` room
- `3` visible stats: `fullness`, `happiness`, `calmness`
- `2` player actions: `Feed`, `Pet`
- fixed loop: `DAY (10s) -> EVENING (15s) -> NIGHT (5s)`
- deterministic rules with seeded request generation

The design goal is clarity over content depth. Every action should have readable cause-and-effect, and the game should be small enough to implement cleanly in Godot.

## Core Gameplay Loop

Each cycle follows the same structure:

- `DAY`: passive recovery phase
- `EVENING`: the cat generates timed requests for `FOOD` or `ATTENTION`
- `NIGHT`: read-only result phase where sleep is evaluated

Sleep is evaluated when `NIGHT` begins:

- `Good Sleep` if `fullness >= 70`, `happiness >= 70`, and `calmness >= 70`
- otherwise `Disturbed Sleep`

## MVP Principles

- Easy to understand in the first minute
- Fully deterministic except for seedable request generation
- Clear UI and feedback at a `1` second tick rate
- Small scene-first Godot architecture with strict state ownership

## Planned Architecture

The implementation is designed around a single authoritative gameplay orchestrator:

- `Main`
- `GameManager`
- `UI`
- `Cat`
- `Player`
- `Environment`

Key architectural rules:

- `GameManager` owns the authoritative `GameState`
- presentation nodes react to state and signals but do not mutate gameplay state
- gameplay runs on a deterministic tick, not frame timing
- tunable values live in data assets rather than being duplicated in scripts

Planned repository layout:

```text
/docs
/scenes
/scripts
/systems
/ui
/data
/tests
```

## Visual and Audio Direction

The MVP direction is a cozy stylized 2D pixel-art game with:

- a single intimate room
- a fixed side-view or light 3/4 presentation
- readable phase changes for `DAY`, `EVENING`, and `NIGHT`
- strong request, timer, and sleep-result feedback
- soft ambient audio and restrained UI feedback

The visual direction is deliberately scoped to support readability and fast implementation rather than broad content variety.

## Project Status

Current status:

- Godot project structure exists with `Main`, `GameManager`, `UI`, `Cat`, `Player`, and `Environment`
- deterministic gameplay rules are implemented in GDScript
- automated gameplay tests exist under `/tests`
- runtime verification is still pending in an environment with a Godot binary

Resolved cross-doc decisions now reflected in the specs:

- `active_request` is canonically `null` when no request is active
- matched requests apply the triggering action's normal stat gain exactly once, with no extra completion bonus

## Documentation

- [Specification](docs/spec.md)
- [Architecture](docs/architecture.md)
- [Art Direction](docs/art_direction.md)
- [Release Checklist](docs/release-checklist.md)

## Implementation Notes

When implementation begins, the expected MVP behavior includes:

- `1` update per second
- player actions accepted only during `DAY` and `EVENING`
- `NIGHT` is read-only
- exactly `3` request windows during each `EVENING`
- all gameplay outcomes reproducible from initial seed plus input sequence

## Roadmap

Next verification work:

1. Open the project in Godot and confirm all scenes/resources load cleanly.
2. Run `godot --headless -s res://tests/run_tests.gd` and fix any runtime issues.
3. Create release exports from the checked-in preset configuration.
4. Replace placeholder presentation/audio with approved MVP assets.

## Contributing

This repository is currently spec-first. If you extend or implement the project:

- keep `docs/spec.md` as the gameplay source of truth
- preserve the ownership boundaries in `docs/architecture.md`
- keep art and UI work aligned with `docs/art_direction.md`
- update `docs/release-checklist.md` as implementation catches up or docs diverge

## License

No license file is present yet.
