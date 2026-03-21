# Cat Chaos Art Direction

## 1. Purpose

Define a production-ready visual, UI, and audio direction for the MVP so humans and AI agents can create assets that support the gameplay in `docs/spec.md`, fit the scene ownership in `docs/architecture.md`, and satisfy the presentation checks in `docs/release-checklist.md`.

This document is for the MVP only. It should optimize for readability, fast implementation, and consistent feedback over asset volume or stylistic complexity.

## 2. Alignment With Product Goals

The art direction must reinforce the core design pillars from the spec:

- easy to understand in the first minute
- clear cause and effect between input and outcome
- small enough to implement quickly in Godot
- visually readable at a 1-second gameplay tick

Implications:

- Prioritize legibility over decorative detail
- Prefer a single strong room composition over multiple backgrounds
- Make request, timer, and sleep-result feedback impossible to miss
- Avoid any visual idea that implies systems the MVP does not have, such as inventory, progression, economy, or multiple pets

## 3. Core Visual Direction

### Style

- Cozy stylized 2D pixel art
- Warm domestic setting
- Light comedic tone, but not chaotic in a visually noisy way
- Simple shapes and clear silhouettes

### Camera and Composition

- Use a fixed side-view or slightly elevated 3/4 room view
- Do not use strict top-down presentation
- The cat must be readable at a glance as the main actor
- The room should feel like a single intimate play space, not an explorable map

Reasoning:

- The spec centers on reading the cat, the current request, the stats, and the sleep outcome
- A strict top-down view makes facial expression, mood, and request feedback harder to communicate in a small MVP
- A side-view or light 3/4 view better supports `Cat`, `UI`, and `Environment` responsibilities from the architecture

### Scene Scope

- MVP contains exactly `1` room
- Compose the room so the cat has a clear resting area, food area, and open idle space
- Keep background props secondary to the cat and HUD
- Avoid dense clutter that competes with request prompts or stat readability

## 4. Phase Presentation

The environment must communicate the fixed loop from the spec:

`DAY (10s) -> EVENING (15s) -> NIGHT (5s)`

### Day

- Brightest lighting state
- Warm daylight palette
- Calm baseline cat pose and low-intensity ambient motion
- Presentation should support the feeling of recovery

### Evening

- Slightly dimmer and warmer lighting
- Strongest gameplay readability for active requests
- Request prompts must visually stand out from the room art
- Cat animation can become more expectant or demanding, but remains readable

### Night

- Darkest lighting state while preserving HUD legibility
- Reduced visual noise because player input is disabled
- Sleep result presentation becomes the focal point
- Environment should visibly differentiate `Good Sleep` from `Disturbed Sleep`

## 5. Cat Direction

The cat is the main expressive element in the MVP.

- Silhouette must remain readable at gameplay scale
- Expressions should communicate calm, needy, satisfied, and upset states
- Animation scope should stay small:
  - idle
  - request reaction
  - satisfied reaction
  - failed-request reaction
  - sleep pose
- Do not design for breed variation, cosmetics, or multiple cats in MVP

Behavior-to-presentation mapping:

- `FOOD` request: cat attention should pull toward food-related anticipation
- `ATTENTION` request: cat should look socially demanding or affectionate
- request success: immediate positive reaction
- request failure: visible disappointment or agitation
- `Good Sleep`: peaceful sleep read
- `Disturbed Sleep`: restless or uneasy sleep read

## 6. UI Direction

UI must satisfy the presentation requirements from the spec and release checklist.

### Required Always-Readable Elements

- current phase
- phase timer
- `fullness`, `happiness`, and `calmness`
- `Feed` and `Pet` actions during `DAY` and `EVENING`

### Required Conditional Elements

- active request type during `EVENING`
- request countdown during `EVENING`
- sleep result during `NIGHT`

### UI Principles

- Basic HUD only
- Large, obvious action buttons for `Feed` and `Pet`
- Strong contrast between gameplay information and decorative art
- Minimal text where icon + label is clearer
- Feedback should read within a single second-long tick
- During `NIGHT`, controls should look clearly disabled or unavailable

### UI Layout Guidance

- Keep the cat and room as the visual center
- Place persistent HUD elements at screen edges
- Keep request prompts near the main play focus without covering the cat entirely
- Sleep result can temporarily take visual priority during `NIGHT`

Do not add UI for out-of-scope systems:

- inventory
- currency
- progression
- quest log
- room navigation

## 7. Color and Lighting

### Palette Goals

- Soft warm palette overall
- Distinct but harmonious lighting states for `DAY`, `EVENING`, and `NIGHT`
- Stats and request prompts must use colors that remain readable against all phase backgrounds

### Recommended Color Behavior

- `DAY`: cream, sun-warm beige, soft honey, muted plant greens
- `EVENING`: amber, peach, dusk orange, muted brick accents
- `NIGHT`: desaturated navy, moonlit teal-gray, muted warm lamp highlights

### Functional Color Use

- `FOOD` request should have a distinct accent color
- `ATTENTION` request should have a different distinct accent color
- success feedback should read as positive immediately
- failure feedback should read as negative immediately without looking harsh or horror-themed

## 8. Pixel and Asset Constraints

- Use one consistent pixel density across cat, props, and environment assets
- Build for a small readable pixel-art presentation rather than high-detail sprite work
- UI can be pixel-art or clean flat rendering, but must visually harmonize with the world art
- Transparent PNG for sprites and UI elements that require alpha
- OGG or WAV for short sound effects
- Loop-friendly ambient audio for background tracks

Grid guidance:

- Treat `32x32` as a planning grid for props and tile-like layout
- Do not force every asset, especially the cat or UI, into a strict `32x32` box

## 9. Audio Direction

Audio should support clarity and mood, not overwhelm the short loop.

### Ambient Direction

- Soft cozy room ambience
- Light daytime ambience, warmer evening ambience, quieter night ambience
- Avoid dense music arrangements that compete with request cues

### Cat Audio

- soft meow
- pleased or affectionate sound
- mildly annoyed sound
- gentle sleep or purr cue if needed

### UI and Gameplay Audio

- soft button click
- request arrival cue
- request success cue
- request failure cue
- sleep result cue for `Good Sleep`
- distinct but restrained sleep result cue for `Disturbed Sleep`

Avoid:

- horror textures
- aggressive alarms
- loud arcade-style feedback
- harsh failure sounds that break the cozy tone

## 10. Asset Production Scope

AI-assisted production is appropriate for:

- concept frames
- placeholder sprites
- icon drafts
- ambient mockups
- rough sound effect drafts

Human review is required before an asset is treated as approved for implementation.

Approval should check:

- gameplay readability
- compatibility with the MVP scope
- consistency with the chosen camera view
- consistency across phase states
- technical usability in Godot

## 11. Integration Targets

This document should align with the architecture ownership rather than invent a separate content structure.

Primary integration targets:

- `Cat` presentation supports `/scenes/actors/Cat.tscn` and `/scripts/actors/cat.gd`
- `Environment` visuals support `/scenes/environment/Environment.tscn`
- HUD and overlays support `/ui/UI.tscn`, `/ui/hud.gd`, `/ui/request_panel.gd`, and `/ui/sleep_result_panel.gd`
- tunable presentation references can be stored in `/data` if needed

If the project later adds a raw asset source tree, keep it additive and consistent with the architecture, for example:

- `/assets/sprites/cat`
- `/assets/sprites/environment`
- `/assets/ui`
- `/assets/audio/sfx`
- `/assets/audio/ambience`

Those raw asset folders must not replace the scene, UI, script, and data ownership defined in `docs/architecture.md`.

## 12. Approval Criteria

An MVP asset set is acceptable when it does all of the following:

- clearly communicates `DAY`, `EVENING`, and `NIGHT`
- keeps the cat as the focal actor
- makes `Feed`, `Pet`, active requests, timers, and sleep results easy to read
- supports a one-room MVP with no implied extra systems
- remains visually and sonically cohesive across `UI`, `Cat`, and `Environment`
- is simple enough to implement quickly in Godot without expanding scope
