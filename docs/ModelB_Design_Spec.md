# Model B — Singing Runner (Design + Spec)

## Goal
Create a voice‑controlled lane runner where the player advances only when singing the target solfege pitch accurately. Model B emphasizes stability, feedback, and a clean scene flow (Title → Calibration → Game → Results).

## Core Loop
1. Game shows target solfege (Do→Re→Mi…)
2. Player sings the target pitch
3. **In‑tune**: move forward, pass obstacles
4. **Off‑pitch**: bounce back, slower progress
5. Clear obstacles → next note
6. Collision → reset to Do, score penalty

## Game States / Scenes
- **Title**: Start, Calibration
- **Calibration**: Set noise gate + confirm mic input; simple steady‑tone check
- **Game (Main)**: Lane runner + obstacles + HUD
- **Results**: Score + retry

## Inputs
- Microphone (AudioStreamMicrophone)
- Pitch detection from `AudioEffectCapture`

## Pitch Detection Spec
- **Method**: Autocorrelation on mono buffer
- **Noise Gate**: RMS threshold prevents false detection
- **Confidence**: Correlation ratio threshold filters noisy frames
- **Smoothing**: Median filter across last 5 pitch estimates
- **Tolerance**: ±50 cents (configurable)

## Scoring
- +10 for each obstacle cleared while in tune
- +1 per second of sustained in‑tune singing
- −10 for collision
- Bonus: complete full octave = +50

## Obstacles
- Vertical blocks with a gap matching the target solfege lane
- Spawn interval: 2.0s (tuneable)
- Collision resets note to Do

## HUD
- Current pitch (Hz)
- Target solfege
- Status (“In tune!” / “Off pitch”)
- Combo or streak

## Audio / Calibration
- Calibration screen prompts a steady Do (C4)
- Uses RMS + pitch stability to confirm mic readiness
- Stores baseline noise floor + recommended min RMS

## Progression / Difficulty
- Level 1: slower obstacles, wider gaps, tighter tolerance
- Level 2: faster obstacles, narrower gaps
- Optional: chromatic mode

## Tech Notes
- Godot 4.2+ required
- Mic permission handling in `_ready()`
- Use `AudioEffectCapture` on a Capture bus

---

# Visuals Plan (Model B)

## Style
- **Minimal neon UI** on dark background
- High‑contrast lane and targets for readability

## Palette
- Background: #101018
- Lane: #141426
- Player: #EAD15A (warm gold)
- In‑tune feedback: #40E09B (mint)
- Off‑pitch feedback: #FF6B6B (coral)
- Obstacles: #D64545

## Lane + Feedback
- Lane segmented into 8 horizontal bands (Do→Do)
- Target band highlighted with glow
- Player sprite pulses when in tune
- Pitch “needle” or meter near HUD

## Obstacles
- Two solid blocks with a gap
- Slight parallax or subtle speed lines

## Results Screen
- Large score, best score, retry button

---

# Prototype Scenes Status
- `scenes/Title.tscn` — basic layout
- `scenes/Calibration.tscn` — placeholder instructions
- `scenes/Results.tscn` — placeholder score screen

---

# Next Steps
1. Wire scene transitions
2. Add calibration logic and store thresholds
3. Add scoring + combo system
4. Visual polish (glow, pulses, background motion)
