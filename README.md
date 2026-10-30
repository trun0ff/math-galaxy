# Math Galaxy v0.5 - Neon Interface Refresh

Godot 4.x, GDScript. This update improves **all** interactive buttons in the game while preserving v0.4 math rules and the shield=0 defeat condition.

## Included
- Unified cyan/indigo neon button treatment across world selection, start, answer choices, hint, skip, exit, retry and result screens
- Consistent corner radii, hover/press states, focus-free touchscreen controls and soft glows
- Enhanced numeric keypad: prominent confirm/delete colors, press bounce, hover light
- Small upgrades to the procedural spaceship, enemies and twinkling star field

## Merge into your existing Git repository
Copy these files into the existing working project, preserving paths:
- `scripts/Main.gd`
- `scripts/ui/NeonKeypad.gd`
- `scripts/SpaceScene.gd`
- `README.md`

Open Godot and press F5. Test world selection, four-choice questions, numeric keyboard, hint, skip, defeat and retry. Your saved progress remains local in Godot's `user://` folder.

Commit only after checking:
```
git add scripts/Main.gd scripts/ui/NeonKeypad.gd scripts/SpaceScene.gd README.md
git commit -m "Polish all game buttons and battle effects"
git push origin main
```

Note: this update has been checked structurally, but not executed inside Godot in this environment. No external art assets are included; the ships remain procedural artwork.
