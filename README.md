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

## Running the Game

This project is configured for Godot `4.6` with `res://scenes/main/Main.tscn` set as the main scene.

On a fresh checkout, import the asset files once before starting the game:

```bash
godot --headless --import --path .
```

Then run the game from the repository root:

```bash
godot --path .
```

If you prefer the editor workflow, open the project in Godot and press `Play`.

## Godot Build Guide

### 1. Prepare Project

- Confirm the main scene is set:
  - `Project -> Project Settings -> Application -> Run -> Main Scene`
- This repository already points to `res://scenes/main/Main.tscn`
- Test the game with `Play`

### 2. Install Export Templates

- Open:
  - `Editor -> Manage Export Templates`
- Click `Download and Install`

### 3. Configure Export

- Open:
  - `Project -> Export`
- Click `Add...`
- Choose a target platform:
  - `Windows`
  - `Linux`
  - `macOS`
  - `Android`
  - `Web (HTML5)`
- This repository already includes a sample `Linux/X11` export preset in `export_presets.cfg`

### 4. Platform Settings

- Set the export path
- Set the output file name

Notes:

- `Windows` typically exports `.exe` and `.pck`
- `Linux` exports a native executable and `.pck` when not embedded
- `Android` requires the Android SDK and a signing keystore
- `Web` generates an `.html` build plus supporting files

### 5. Export Build

- Click `Export Project` for a single target
- Or click `Export All` to build every configured preset

### 6. Test Build

Run the exported output for the selected platform:

- `Windows` -> `.exe`
- `Linux` -> native executable
- `Android` -> `.apk`
- `Web` -> open the generated `.html`

### 7. Share

- Zip the exported files if needed
- Upload them to your release channel, such as `itch.io`

### CLI Export (Optional)

Once a preset is configured, you can export from the command line. For the sample Linux preset in this repository:

```bash
godot --headless --path . --export-release "Linux/X11" build/cat-chaos.x86_64
```

### Export with Make

This repository also includes a [`Makefile`](Makefile) to wrap the Godot export commands.

First-time setup checklist:

- Install `make`
- Install `godot` and ensure it is available on your `PATH`
- Install Godot export templates
- Import project assets once with `make import` or `godot --headless --import --path .`
- Confirm the required export preset exists in `export_presets.cfg`

From the repository root, the first export run is:

```bash
make
```

The default `all` target currently runs `clean` and `linux`, which exports the Linux build to `build/linux/`.

Other useful targets:

```bash
make import
make clean
make linux
make windows
make web
```

If Godot is installed outside your shell `PATH`, pass it explicitly:

```bash
make GODOT=/full/path/to/godot
```

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
