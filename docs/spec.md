# Cat Chaos Specification

## 1. Goal

Cat Chaos is a small 2D pet-care game. The player manages one cat through a repeating day cycle and tries to reach night with the cat fed, happy, and calm enough for a peaceful sleep.

The MVP should favor deterministic rules and readable feedback over content depth.

## 2. Core Loop

The game repeats this fixed loop:

`DAY (10s) -> EVENING (15s) -> NIGHT (5s) -> repeat`

- `DAY`: passive recovery phase
- `EVENING`: request / reaction phase
- `NIGHT`: result phase with no player input

## 3. Design Pillars

- Easy to understand in the first minute
- Fully deterministic except for seedable request generation
- Small enough to implement quickly in Godot
- Clear cause and effect between player actions and sleep outcome

## 4. Single Source of Truth

```ts
type Phase = "DAY" | "EVENING" | "NIGHT";
type RequestType = "FOOD" | "ATTENTION";

type ActiveRequest =
  | null
  | {
      type: RequestType;
      time_remaining: number; // seconds, integer
    };

type GameState = {
  phase: Phase;
  phase_time_remaining: number; // seconds, integer
  fullness: number; // 0-100, higher is better
  happiness: number; // 0-100, higher is better
  calmness: number; // 0-100, higher is better
  active_request: ActiveRequest;
  cycle_index: number;
  rng_state: number;
};
```

### Initial State

```ts
{
  phase: "DAY",
  phase_time_remaining: 10,
  fullness: 80,
  happiness: 80,
  calmness: 60,
  active_request: null,
  cycle_index: 1,
  rng_state: <seeded value>
}
```

## 5. Time and Tick Rules

- Tick rate: `1 update per second`
- All game logic runs on the tick
- All numeric stats are clamped to `0..100`
- Player actions are accepted only during `DAY` and `EVENING`
- `NIGHT` is read-only

## 6. Passive Stat Rules

Passive rules apply once per tick during `DAY` and `EVENING`.

- `fullness -= 1`
- `happiness -= 1`
- During `DAY` only: `calmness += 2`

No passive stat changes happen during `NIGHT`.

## 7. Request System

Requests happen only during `EVENING`.

### Evening Structure

- `EVENING` lasts `15` seconds
- It is split into `3` request windows of `5` seconds each
- Each window creates exactly `1` request
- Only `1` request may be active at a time

### Request Generation

- A request is generated at the start of each 5-second window
- Request type is chosen by seedable RNG from:
  - `FOOD`
  - `ATTENTION`
- The request timer starts at `5`

### Request Resolution

- If the player satisfies the matching request before the timer reaches `0`, the request is completed immediately
- If the timer reaches `0`, the request is ignored / failed

### Request Effects

- `FOOD` completed: `fullness += 20`
- `ATTENTION` completed: `happiness += 20`
- Any ignored request:
  - `happiness -= 10`
  - `calmness -= 10`

## 8. Player Actions

| Action | Availability | Effect |
| --- | --- | --- |
| `Feed` | `DAY`, `EVENING` | `fullness += 20`; if the active request is `FOOD`, complete it |
| `Pet` | `DAY`, `EVENING` | `happiness += 20`; if the active request is `ATTENTION`, complete it |

There is no explicit `Ignore` button. A request is considered ignored when its timer expires unresolved.

## 9. Phase Transitions

- `DAY -> EVENING` when `phase_time_remaining` reaches `0`
- `EVENING -> NIGHT` when `phase_time_remaining` reaches `0`
- `NIGHT -> DAY` when `phase_time_remaining` reaches `0`

### On Enter Day

- Set `phase_time_remaining = 10`
- Clear `active_request`
- Increment `cycle_index` by `1`

### On Enter Evening

- Set `phase_time_remaining = 15`
- Start the first request window immediately

### On Enter Night

- Set `phase_time_remaining = 5`
- Clear `active_request`
- Evaluate sleep outcome once

## 10. Sleep Evaluation

Sleep is evaluated exactly once when `NIGHT` begins.

### Outcome Rule

- `Good Sleep` if:
  - `fullness >= 70`
  - `happiness >= 70`
  - `calmness >= 70`
- Otherwise: `Disturbed Sleep`

This rule replaces the previous average-score approach because the stricter threshold is easier to understand and matches the intended acceptance criteria.

## 11. Deterministic Update Order

For each tick, process logic in this order:

1. Apply player input for the current tick
2. Apply passive stat rules for the current phase
3. Update the active request timer and resolve completion / timeout
4. Decrement `phase_time_remaining`
5. Perform phase transition if the timer reached `0`
6. If a new evening request window starts, spawn the next request

This ordering must remain fixed so tests and gameplay stay deterministic.

## 12. Events

The game should emit these events:

- `OnPhaseChanged(from_phase, to_phase)`
- `OnRequestGenerated(request_type)`
- `OnRequestCompleted(request_type)`
- `OnRequestFailed(request_type)`
- `OnSleepEvaluated(result)`

## 13. Acceptance Tests

### Sleep Outcome

- Given `fullness = 70`, `happiness = 70`, `calmness = 70` at the start of `NIGHT`, the result is `Good Sleep`
- Given any one of those stats is below `70` at the start of `NIGHT`, the result is `Disturbed Sleep`

### Requests

- Given one `EVENING` phase, exactly `3` requests are generated
- Given an active `FOOD` request, `Feed` completes it on the same tick
- Given an active `ATTENTION` request, `Pet` completes it on the same tick
- Given a request expires, `happiness` and `calmness` are both reduced by `10`

### Stat Bounds

- Stats never go below `0`
- Stats never go above `100`

## 14. Godot MVP Structure

Recommended node / responsibility split:

- `Main`
- `GameManager`
- `Cat`
- `UI`
- `Environment`

Suggested ownership:

- `GameManager`: state, ticks, transitions, request logic
- `Cat`: animation / reaction hooks
- `UI`: bars, timers, action buttons, sleep result
- `Environment`: room visuals and phase-based presentation

## 15. MVP Scope

The first playable version includes:

- `1` room
- `1` cat
- `3` visible stats
- Fixed day / evening / night loop
- Two actions: `Feed`, `Pet`
- Request prompts during evening
- Sleep result screen during night
- Basic UI only, no inventory, progression, or save system

## 16. Out of Scope for MVP

- Multiple pets
- Personality system
- Long-term progression
- Economy or shop
- Procedural events outside the request system

## 17. Future Extensions

- Cat personalities that bias request frequency
- More request types
- Multiple-room apartment
- Persistent progression between days
- Difficulty scaling by cycle count
