# Solfege Runner (Godot 4)

Voice‑controlled lane runner using solfege (Do‑Re‑Mi‑Fa‑Sol‑La‑Ti‑Do). Sing the target pitch to move forward. Off‑pitch bounces you back. Obstacles have gaps.

## Project Structure
- `scenes/Main.tscn` – main scene
- `scripts/Main.gd` – gameplay + pitch detection
- `project.godot` – project settings

## Requirements
- Godot 4.2+ (Windows build for export)
- Microphone access

## How It Works
- Targets C major: C4→C5
- Pitch detection via microphone using `AudioEffectCapture` + autocorrelation
- In‑tune: move forward (right). Off‑pitch: bounce back (left)
- Obstacles are vertical blocks with a gap; hitting them resets to Do

## Run in Editor
1. Open Godot 4.x
2. Import the project folder `solfege-runner-godot`
3. Run the Main scene
4. Allow microphone permissions if prompted

## Windows Export Preset
1. **Install export templates**: Editor → Manage Export Templates
2. **Project → Export…**
3. Add preset: **Windows Desktop**
4. Set:
   - Export Path: `builds/SolfegeRunner.exe`
   - Architecture: x86_64
   - Embed PCK: On
5. Click **Export Project**

## Notes
- If you don’t hear mic input, make sure your system mic is selected and enabled.
- Tuning tolerance is ±50 cents. You can adjust `cents_tolerance` in `Main.gd`.
- Targets are fixed to C major: Do=C4.

## Troubleshooting
- **No pitch detected**: increase input gain in OS, or reduce background noise.
- **Laggy response**: reduce the audio buffer size in code by requiring fewer frames.

