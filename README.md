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


## v0.6 - Illustrated Space Combat
- New original PNG ship and 3 animated enemy variants in `assets/battle/`.
- Painted nebula with stars and distant planet, composited with existing moving star layer.
- Engine plume, laser, shield damage, debris and ship destruction preserved.
- All v0.5 UI, button visuals, math and save code unchanged.
- Import this folder with Godot 4 and press F5; replace `scripts/SpaceScene.gd` and add `assets/battle/` in an existing project.
- Artistic sprites are original vector-generated assets; no outside copyrighted graphics.


## v0.7 - worlds and persistent enemy damage
- Five illustrated world cards replace plain world buttons. Art in `assets/worlds/`.
- Enemies keep their identity across successful hits (3 HP normal, 6 HP boss). On zero HP, a particle burst plays and a new enemy appears.
- Persistent HP bar, damage cracks, hit shake, and sparks on heavily damaged enemies.
- More atmospheric nebula background; math logic and keypad remain unchanged.
- Import by copying archive contents over your existing project, preserving `.git` and `.godot`.
- Project not runtime-tested in Godot; use F5 to validate UI layout and combat.
