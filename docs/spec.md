# SPEC.md

## 🐱 Game Title

Cat & Human: Night Peace

---

## 1. 🎯 Purpose

A simple 2D simulation game designed to encourage responsible pet care through short, engaging gameplay loops.

The player controls a human character responsible for meeting a cat’s needs. Proper care during the day and evening determines whether the player can sleep peacefully at night.

---

## 2. 🧩 Core Concept

The game is built around a repeating **time-cycle loop**:

- Day → Evening → Night → Repeat

Player actions during **Day** and **Evening** directly affect the outcome of the **Night phase**.

---

## 3. 👤 Characters

### 3.1 Owner (Player)

- Human character
- Selectable: Boy / Girl
- Role: Respond to pet needs

### 3.2 Pet (Cat)

- Autonomous behavior
- Nocturnal tendencies
- Generates needs:
  - Hunger
  - Attention
  - Sleep

---

## 4. ⚙️ Core Systems

### 4.1 Pet Stats

| Stat      | Range | Description        |
| --------- | ----- | ------------------ |
| Hunger    | 0–100 | Need for food      |
| Happiness | 0–100 | Need for attention |
| Energy    | 0–100 | Rest level         |

---

### 4.2 Time System

The game progresses in discrete phases:

1. **Day**
   - Cat sleeps
   - Energy increases
   - Player should not disturb

2. **Evening**
   - Cat is active
   - Requests needs (food, attention)

3. **Night**
   - Outcome phase
   - Determines sleep quality

---

### 4.3 Needs System

During Evening, the cat generates requests:

- Food
- Attention

Each request:

- Has a time window
- Requires player action

---

### 4.4 Player Actions

| Action     | Effect                       |
| ---------- | ---------------------------- |
| Feed       | +Hunger                      |
| Pet        | +Happiness                   |
| Do Nothing | No effect / negative outcome |

---

### 4.5 Sleep Evaluation

At Night phase:
IF Hunger > 70 AND Happiness > 70 AND Energy > 70:
Result = Good Sleep
ELSE:
Result = Disturbed Sleep

---

## 5. 🔁 Gameplay Loop

1. Start Day
2. Cat sleeps → gains energy
3. Transition to Evening
4. Cat requests needs
5. Player responds (or not)
6. Transition to Night
7. Evaluate outcome
8. Repeat cycle

---

## 6. 🏠 Environment

### MVP Scope

- Single room (Living Room)

### Future Expansion

- Kitchen (feeding)
- Bedroom (sleep)
- Bathroom (optional interactions)

---

## 7. 🎮 Interaction Model

### Input

- Mouse / Touch

### UI Elements

- Buttons:
  - Feed
  - Pet
- Stat bars:
  - Hunger
  - Happiness
  - Energy

---

## 8. 🧠 Game Logic

### 8.1 Request Generation

- Triggered during Evening
- Randomized:

IF random < 0.5:
request = FOOD
ELSE:
request = ATTENTION

---

### 8.2 Stat Decay

Over time:

- Hunger decreases
- Happiness decreases

Energy:

- Increases during Day
- Decreases slightly during Evening/Night

---

## 9. 🎬 Feedback System

### Immediate Feedback

- Success:
  - Cat purrs
  - Positive animation
- Failure:
  - Meow (loud/annoyed)
  - Agitated animation

### Night Feedback

- Good Sleep:
  - Calm visuals
  - Quiet night
- Bad Sleep:
  - Repeated meowing
  - Screen interruptions

---

## 10. 🧱 Godot Architecture

### 10.1 Scene Structure

Main (Node)
├── GameManager (Node)
├── UI (CanvasLayer)
│ ├── Buttons
│ ├── StatBars
├── Cat (CharacterBody2D or Node2D)
├── Player (Node2D)
└── Environment (Node2D)

---

### 10.2 Scripts

- `GameManager.gd`
  - Controls time phases
  - Manages state transitions

- `Cat.gd`
  - Handles needs
  - Generates requests

- `UI.gd`
  - Updates stats display
  - Handles player input

---

### 10.3 State Machine

STATE_DAY
STATE_EVENING
STATE_NIGHT

---

## 11. 📊 Balancing (Initial Values)

| Stat      | Start | Decay Rate |
| --------- | ----- | ---------- |
| Hunger    | 50    | -5 / cycle |
| Happiness | 50    | -5 / cycle |
| Energy    | 50    | +10 (Day)  |

---

## 12. 🚀 MVP Scope

### Must Have

- 1 room
- 1 cat
- 3 stats
- 3 phases (Day/Evening/Night)
- Basic UI (buttons + bars)
- Sleep outcome system

### Not Required (yet)

- Animations
- Sound effects
- Multiple rooms
- Save system

---

## 13. 🔮 Future Enhancements

- Cat personalities (needy, lazy, chaotic)
- Multiple pets
- Sound system (meows, purring)
- Mobile support
- Progression system
- Owner fatigue system

---

## 14. ✅ Success Criteria

The game succeeds if:

- Player understands cause → effect
- Short gameplay loop feels engaging
- Emotional connection with the pet is created
- Player aims to achieve “good sleep” consistently

---

## 15. 🧪 Testing Notes

- Validate stat thresholds feel fair
- Ensure feedback is immediate and clear
- Avoid overwhelming the player with too many requests
- Keep interaction loop under ~30 seconds

---

## 16. 📌 Technical Notes

- Engine: Godot 4.x
- Resolution: 1280x720 (recommended)
- Input: Mouse / Touch compatible
- Target: Web (HTML5 export) or Desktop

---
