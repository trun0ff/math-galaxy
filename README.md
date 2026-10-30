# Math Galaxy v0.8 - Illustrated Worlds & Sci-fi Buttons

Godot 4.x. This release upgrades the existing v0.7 project without changing the mathematics, reward logic, or loss rules.

## New in 0.8
- Five illustrated high-resolution world cards (HD versions in assets/worlds).
- Five distinct battle backgrounds selected to match each world (assets/battle/world_*_background.jpg).
- Custom reusable polygonal sci-fi button art drawn by scripts/ui/FancyButton.gd. All buttons created by Main.gd use the shared component.
- Original scripts and save format retained.

## Upgrade
Unzip the complete package over the files in your Git working tree. Leave your .git and .godot folders untouched. Run F5 in Godot, verify the five worlds, the battle, keypad, victory and loss screens. Commit only after checking the result.

## Notes
The illustrated world cards and background composites are made from newly generated concept artwork rather than the old low-resolution geometric planets. The images are JPEGs, not individually transparent PNG planetary sprites. Godot execution has not been tested in this environment.
