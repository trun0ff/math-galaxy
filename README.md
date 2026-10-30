# Math Galaxy v0.4 - Neon Controls

Godot 4 project. Uses the existing v0.3 math and gameplay rules.

## New in v0.4
- Separate reusable neon numeric keypad (`scripts/ui/NeonKeypad.gd`)
- Larger buttons, colored OK / delete, hover and press feedback
- Animated answer display
- Styled shield and question timer bars
- Styled answer-choice buttons and menu buttons
- Existing space effects and ship-destruction flow retained

## Update existing Git project
Copy `scripts/Main.gd`, `scripts/ui/NeonKeypad.gd` and `README.md` into your existing project, preserving folder names. Then reopen or refresh Godot and press F5. Alternatively import `project.godot` from this complete archive.

## Controls
Numeric mode: keypad or computer number keys, Enter, Backspace.
Choice mode: choose one of four answers.

## Suggested commit
`git add scripts/Main.gd scripts/ui/NeonKeypad.gd README.md && git commit -m "Add neon keypad and battle HUD styling" && git push origin main`

## Notes
This version is intended as a visual/UI iteration; it does not add new gameplay rules. It has not been runtime-tested in the Godot editor in this environment.
