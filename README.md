# Math Galaxy - Godot prototype v0.3

A lightweight, offline 2D mathematics arcade for Godot 4.x, written in GDScript.

## Run

1. Open Godot Project Manager -> Import.
2. Select `project.godot` from this directory.
3. Press F5 to play.

## What's new in v0.3

- Multi-speed parallax starfield and subtle nebula backdrop.
- Smoother thruster glow and ship movement.
- Three enemy variants, laser glow, impact debris, expanding shockwaves.
- Shield-hit shake and debris.
- At 0% shield: 1.65-second ship explosion before the game-over screen.
- **Retry Level** resets the mission. Practice stats are still kept, but failed missions award no crystals.

## Project files

- `scripts/Main.gd`: menus, mission state, question flow, shields, rewards, saved progress.
- `scripts/MathEngine.gd`: generators for all five worlds.
- `scripts/SpaceScene.gd`: drawn space battle and particle-like effects.
- `scenes/Main.tscn`: main scene.

This v0.3 is an incremental graphical update, not a finished game. Graphics are procedural; no external artwork or audio is required. This archive has been structurally checked but not run inside the Godot editor in this environment.

## Git

Replace tracked project files in your local clone, then:

```bash
git status
git add scripts/SpaceScene.gd scripts/Main.gd README.md
git commit -m "Add space battle visual effects and ship destruction animation"
git push origin main
```

`.godot/` should be excluded via `.gitignore`.
