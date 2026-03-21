# Cat Chaos Architecture

## 1. Overview

Cat Chaos is built as a small set of focused Godot scenes coordinated by a single gameplay orchestrator. The architecture is scene-first, node-based, signal-driven, and state-driven so the implementation stays deterministic and easy to evolve.

Key decisions:

- `GameManager` owns the authoritative `GameState`
- Scenes are split by responsibility: gameplay, presentation, input, environment
- Nodes communicate through signals instead of hard references where possible
- Balance values live outside code in data assets
- Autoloads are avoided for core gameplay; the main scene is enough for MVP composition

This structure fits a spec-driven workflow because the spec maps directly to stable systems: phases, tick updates, requests, sleep evaluation, and UI feedback. AI agents can implement each system against clear boundaries without rewriting the whole tree.

## 2. Core Architecture Pattern

### Scene-Based Composition

Each major game concern is its own scene or node subtree:

- `Main` composes the playable screen
- `GameManager` runs game rules
- `Cat` handles cat-facing behavior and reactions
- `Player` converts player intent into gameplay actions
- `UI` renders state and exposes buttons / prompts
- `Environment` changes visuals by phase

This keeps scenes reusable and lets each part be tested in isolation.

### GameManager as Orchestrator

`GameManager` is the central coordinator, not a dumping ground. It owns:

- game clock
- phase transitions
- authoritative `GameState`
- deterministic tick processing
- rule application
- sleep evaluation

It does not own animation, button rendering, or cat presentation logic.

### Signal-Driven Communication

Godot signals are the primary decoupling mechanism, similar to an observer pattern in the engine's own model ([Godot docs](https://docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html)). Signals are used because they:

- reduce direct dependencies between scenes
- make systems replaceable without rewriting call sites
- keep presentation nodes independent from simulation rules
- fit Godot's editor and runtime workflow naturally

### State-Driven Logic

Gameplay flows from state changes, not ad hoc node behavior. Nodes read `GameState` snapshots and react:

- UI redraws bars and timers
- Cat changes animation or mood
- Environment swaps phase visuals
- Player input becomes action intents that `GameManager` validates against current state

## 3. Scene Tree Structure

```text
Main
├── GameManager
├── UI
├── Cat
├── Player
└── Environment
```

Responsibilities:

- `Main`
  - root composition scene
  - owns references to top-level children
  - performs signal wiring in `_ready()`
- `GameManager`
  - authoritative simulation controller
  - owns `GameState`
  - emits gameplay events
- `UI`
  - HUD, request prompt, action buttons, phase labels, sleep result
  - emits player-facing intents from buttons
  - never changes game state directly
- `Cat`
  - animation controller and cat feedback node
  - reacts to requests, completion, failure, and phase changes
  - may propose request flavor, but does not own state writes
- `Player`
  - maps keyboard, mouse, and touch actions into `feed` / `pet` intents
  - can later become a visible avatar without changing game rules
- `Environment`
  - room visuals, lighting, sound cues, and phase mood changes

Recommended child layout:

```text
UI
├── HUD
├── ActionButtons
├── RequestPanel
└── SleepResultPanel

Cat
├── Sprite2D
├── AnimationPlayer
└── AudioStreamPlayer2D

Environment
├── Background
├── Props
└── PhaseFX
```

## 4. Game State Model

`GameState` is the single source of truth for gameplay.

Note on naming: the current spec uses `fullness` and `calmness` as the canonical names. If older docs still refer to `hunger` and `energy`, treat them as legacy labels and do not keep both in code.

```gdscript
class_name GameState
extends Resource

enum Phase { DAY, EVENING, NIGHT }

var phase: Phase
var phase_time_remaining: int
var fullness: int
var happiness: int
var calmness: int
var active_request # null or { type: StringName, time_remaining: int }
var cycle_index: int
var rng_state: int
```

Ownership rules:

- Owner: `GameManager`
- Readers: `UI`, `Cat`, `Environment`, `Player`, test harnesses
- Writers: `GameManager` only

Modification rule:

- No node other than `GameManager` mutates `GameState`
- Other systems send intents or signals
- `GameManager` validates, applies, clamps, and emits the resulting state change

This keeps deterministic behavior and prevents UI or animation code from becoming hidden game logic.

## 5. System Responsibilities

### GameManager

- own and initialize `GameState`
- run the 1-second tick timer
- apply passive stat decay / recovery
- manage phase transitions
- create and resolve requests
- apply action rewards exactly once for matched requests
- evaluate sleep outcome
- emit state and domain signals

### Cat

- present cat mood through animation and audio
- react to request lifecycle events
- expose behavior helpers for request presentation
- optionally provide request flavor rules later, while `GameManager` still owns the committed request

### UI

- render stats, timers, current phase, active request, and sleep result
- expose button presses as signals
- stay stateless beyond display-only widget state

### Player

- collect keyboard, mouse, and touch input
- translate input into domain intents such as `feed_requested` and `pet_requested`
- remain independent from game rule logic

### Environment

- update room visuals based on phase
- provide visual feedback for peaceful vs disturbed night
- remain purely presentational in MVP

## 6. Signal Architecture

Use signals for domain events and player intents. Prefer connecting signals once in `Main` or via exported references during setup. Do not scatter `get_node()` lookups through gameplay code.

| Signal              | Emitter        | Listener                   | Payload                          |
| ------------------- | -------------- | -------------------------- | -------------------------------- |
| `feed_requested`    | `UI`, `Player` | `GameManager`              | none                             |
| `pet_requested`     | `UI`, `Player` | `GameManager`              | none                             |
| `tick_processed`    | `GameManager`  | `UI`, `Cat`, `Environment` | `state: GameState`               |
| `phase_changed`     | `GameManager`  | `UI`, `Cat`, `Environment` | `from_phase`, `to_phase`         |
| `request_generated` | `GameManager`  | `UI`, `Cat`                | `request_type`, `time_remaining` |
| `request_completed` | `GameManager`  | `UI`, `Cat`                | `request_type`                   |
| `request_failed`    | `GameManager`  | `UI`, `Cat`, `Environment` | `request_type`                   |
| `sleep_evaluated`   | `GameManager`  | `UI`, `Environment`, `Cat` | `result`, `state: GameState`     |
| `state_changed`     | `GameManager`  | `UI`, `Cat`, `Environment` | `state: GameState`               |

Recommended flow:

```text
Player / UI
   -> action intent signal
GameManager
   -> validate against GameState
   -> mutate GameState
   -> emit domain signals
UI / Cat / Environment
   -> update visuals only
```

Signal rules:

- Emit domain-level signals, not node-level implementation details
- Payloads should be small and explicit
- Prefer one-way flow: intent in, state/event out
- Avoid child nodes calling gameplay methods on sibling nodes directly

## 7. Update Loop (Tick System)

The simulation is tick-based at `1 second` per update. A `Timer` owned by `GameManager` drives the loop.

Recommended implementation:

- `GameManager` owns a child `Timer`
- `wait_time = 1.0`
- `one_shot = false`
- `autostart = true`
- `_on_tick_timeout()` runs the full simulation step

Deterministic tick order:

1. consume any queued player intent for this tick
2. apply action effects
3. apply passive stat changes for current phase
4. update request timer and resolve completion or failure
5. decrement `phase_time_remaining`
6. perform phase transition if needed
7. spawn next request window if evening requires it
8. clamp values and emit `state_changed`

Rules:

- no frame-rate dependent gameplay logic
- no state mutation in `_process()`
- all gameplay outcomes must be reproducible from initial seed + input sequence
- when an action matches the active request, the action's normal stat gain is the only stat reward; request completion adds no extra bonus

## 8. Data & Configuration

Balance and tunable values should live outside gameplay scripts.

Recommended options:

- `Resource` for editor-friendly tuning in Godot
- JSON only if external tooling needs raw text interchange

Preferred MVP structure:

```gdscript
class_name GameConfig
extends Resource

@export var day_duration: int = 10
@export var evening_duration: int = 15
@export var night_duration: int = 5
@export var request_window_duration: int = 5
@export var fullness_decay_per_tick: int = 1
@export var happiness_decay_per_tick: int = 1
@export var calmness_gain_day_per_tick: int = 2
@export var feed_amount: int = 20
@export var pet_amount: int = 20
@export var request_fail_happiness_penalty: int = 10
@export var request_fail_calmness_penalty: int = 10
@export var sleep_threshold: int = 70
```

Why externalize config:

- balancing does not require code edits
- tests can run with alternate configs
- agents can adjust data safely without changing system behavior
- future difficulty modes become data problems instead of branching logic

## 9. Folder Structure

```text
/docs
  spec.md
  architecture.md
/scenes
  main/Main.tscn
  gameplay/GameManager.tscn
  actors/Cat.tscn
  actors/Player.tscn
  environment/Environment.tscn
/scripts
  main/main.gd
  gameplay/game_manager.gd
  actors/cat.gd
  actors/player.gd
/systems
  tick_system.gd
  request_system.gd
  sleep_evaluator.gd
/ui
  UI.tscn
  ui_root.gd
  hud.gd
  request_panel.gd
  sleep_result_panel.gd
/data
  game_config.tres
  request_definitions.tres
  test_configs/
/tests
  unit/
  integration/
```

Guideline:

- scenes define composition
- scripts define behavior
- systems contain pure or near-pure gameplay logic helpers
- data contains tunable resources
- UI stays separate from simulation code

## 10. Anti-Patterns to Avoid

- God object `GameManager` that also animates the cat, manages UI widgets, and stores config
- Tight coupling through hard-coded node paths such as deep `get_node("../../UI/...")`
- Autoloading gameplay state just because it is convenient
- Mutating gameplay state directly from UI button handlers
- Putting sleep evaluation rules in UI panels
- Using `_process()` for simulation timing
- Duplicating balance values across scripts
- Letting `Cat` or `Player` mutate authoritative stats directly

## 11. Future Scalability

This structure scales without rewriting the core loop.

### Multiple Pets

- add `PetController` parent or array-based pet registry under `GameManager`
- keep one authoritative state object per pet or one aggregate world state resource
- reuse `Cat.tscn` as an instanced actor scene

### Personalities

- add personality data resources that modify request generation weights and reactions
- keep those modifiers in data, not in UI or scene composition

### Progression Systems

- introduce a progression service or system that reads outcomes after each cycle
- keep progression state separate from per-run simulation state

### Save / Load

- serialize `GameState` plus config/version metadata
- add a dedicated persistence service later, preferably as a narrow autoload only when save/load is introduced

### Agentic Development Fit

- agents can implement one scene or one system at a time
- deterministic state and explicit signals reduce merge conflicts
- externalized config allows safe balancing changes without architecture churn
