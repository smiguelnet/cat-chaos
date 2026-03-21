# Release Checklist

## 1. Current Verification Status

- [ ] Confirm the repository contains the implementation described in the architecture:
  - `/scenes`
  - `/scripts`
  - `/systems`
  - `/ui`
  - `/data`
  - `/tests`
- [ ] Confirm a playable Godot project exists (`project.godot`, main scene, resources, scripts).
- [ ] Confirm automated tests exist for the gameplay rules in `docs/spec.md`.

### Status Today

- Current repository contents are documentation only: `docs/spec.md`, `docs/architecture.md`, and this checklist.
- The game implementation is not present, so the game cannot be verified as correct yet.
- The previous spec/architecture consistency issues have been resolved in the docs:
  - `active_request` is canonically `null` when no request is active.
  - Matching a request applies the triggering action's normal stat gain exactly once and adds no extra completion bonus.

## 2. Pre-release Validation

### Repository and Architecture Checks

- [ ] `Main` composes the top-level scene tree defined in `docs/architecture.md`:
  - `GameManager`
  - `UI`
  - `Cat`
  - `Player`
  - `Environment`
- [ ] `GameManager` is the only writer to `GameState`.
- [ ] `UI`, `Cat`, `Player`, and `Environment` do not mutate authoritative gameplay state directly.
- [ ] Core gameplay does not rely on autoloads.
- [ ] Tunable values live in data/resources, not duplicated across scripts.
- [ ] Signals are used for intents and domain events rather than deep node-path coupling.
- [ ] No gameplay state mutation happens in `_process()`.

### Core Gameplay Rule Checks

- [ ] Initial state matches the spec:
  - `phase = DAY`
  - `phase_time_remaining = 10`
  - `fullness = 80`
  - `happiness = 80`
  - `calmness = 60`
  - `active_request = null`
  - `cycle_index = 1`
  - seeded `rng_state`
- [ ] Tick rate is exactly `1 update per second`.
- [ ] Gameplay is deterministic from initial seed plus input sequence.
- [ ] Update order matches the spec and remains fixed.
- [ ] Player actions are accepted only during `DAY` and `EVENING`.
- [ ] `NIGHT` is read-only.
- [ ] All stats are clamped to `0..100`.

### Passive Stat Checks

- [ ] During `DAY`, `fullness -= 1`, `happiness -= 1`, and `calmness += 2` per tick.
- [ ] During `EVENING`, `fullness -= 1` and `happiness -= 1` per tick.
- [ ] During `NIGHT`, no passive stat changes occur.

### Request System Checks

- [ ] Requests occur only during `EVENING`.
- [ ] `EVENING` lasts `15` seconds.
- [ ] `EVENING` is split into exactly `3` windows of `5` seconds each.
- [ ] Exactly `1` request is generated at the start of each request window.
- [ ] Only `1` request may be active at a time.
- [ ] Request type is chosen from `FOOD` and `ATTENTION` using seeded RNG.
- [ ] Each generated request starts with `time_remaining = 5`.
- [ ] `Feed` completes an active `FOOD` request on the same tick.
- [ ] `Pet` completes an active `ATTENTION` request on the same tick.
- [ ] When a request expires unresolved, `happiness -= 10` and `calmness -= 10`.
- [ ] When a request is matched, the triggering action applies its normal stat gain exactly once.
- [ ] Request completion adds no extra stat reward beyond the triggering action.

### Phase Transition Checks

- [ ] `DAY -> EVENING` when `phase_time_remaining` reaches `0`.
- [ ] `EVENING -> NIGHT` when `phase_time_remaining` reaches `0`.
- [ ] `NIGHT -> DAY` when `phase_time_remaining` reaches `0`.
- [ ] Entering `DAY` resets `phase_time_remaining` to `10`, sets `active_request = null`, and increments `cycle_index`.
- [ ] Entering `EVENING` resets `phase_time_remaining` to `15` and starts the first request window immediately.
- [ ] Entering `NIGHT` resets `phase_time_remaining` to `5`, sets `active_request = null`, and evaluates sleep once.

### Sleep Evaluation Checks

- [ ] Sleep is evaluated exactly once when `NIGHT` begins.
- [ ] `Good Sleep` requires:
  - `fullness >= 70`
  - `happiness >= 70`
  - `calmness >= 70`
- [ ] If any one of those stats is below `70`, the result is `Disturbed Sleep`.

### Event / Signal Checks

- [ ] Phase change event/signal is emitted with previous and new phase.
- [ ] Request generated event/signal is emitted with request type.
- [ ] Request completed event/signal is emitted with request type.
- [ ] Request failed event/signal is emitted with request type.
- [ ] Sleep evaluated event/signal is emitted with the result.
- [ ] State updates emitted to presentation layers do not bypass `GameManager`.

## 3. UI and Player Experience Checks

- [ ] The player can trigger `Feed` and `Pet` through the intended controls.
- [ ] Action buttons are disabled or ignored during `NIGHT`.
- [ ] The current phase is always visible.
- [ ] The phase timer is always visible and updates once per tick.
- [ ] All three stats are visible and reflect authoritative state.
- [ ] The active request and remaining request time are visible during `EVENING`.
- [ ] Sleep result is clearly shown during `NIGHT`.
- [ ] Cat reactions and environment changes track state changes without affecting game logic.
- [ ] There is clear player feedback for:
  - request generated
  - request completed
  - request failed
  - sleep result

## 4. Test Gate

- [ ] Unit tests cover the acceptance tests from `docs/spec.md`.
- [ ] Unit tests cover stat clamping at both lower and upper bounds.
- [ ] Unit tests cover deterministic request generation from a fixed seed.
- [ ] Unit tests cover the full tick update order.
- [ ] Unit tests cover phase transitions and `cycle_index` increment behavior.
- [ ] Integration tests or deterministic simulations cover at least one full `DAY -> EVENING -> NIGHT -> DAY` cycle.
- [ ] Manual playthrough confirms exactly `3` requests in one evening and correct sleep evaluation at night.
- [ ] Regression tests exist for any previously fixed gameplay bugs.

## 5. Build and Packaging

- [ ] The Godot project opens without missing resource, missing script, or broken scene errors.
- [ ] The configured main scene starts successfully.
- [ ] Input mappings required by `Player` are present in project settings.
- [ ] Export presets exist for the intended release platform(s).
- [ ] A release export runs successfully on each target platform.
- [ ] Release artifacts contain the required scenes, scripts, resources, and data assets.
- [ ] Version number and project metadata are updated for the release.
- [ ] Changelog or release notes describe user-visible gameplay or balance changes.
- [ ] Release tag uses the chosen semantic version.

## 6. Post-release

- [ ] Push the release tag.
- [ ] Publish release notes.
- [ ] Record known limitations or deferred design decisions.
- [ ] Update docs if implementation diverged from the current spec or architecture.
