# Battle art

Generated with the built-in image_gen tool, 2026-10-31, using the user's two Math Galaxy screenshots as visual references.

Files: fleet_atlas.png (source atlas), fighter_cyan.png, fighter_gold.png, fighter_violet.png, monster_cyclops.png, monster_mech.png, monster_crystal.png. Individual sprites are cell crops trimmed to their alpha bounds; transparency is preserved.

Generation prompt:
Production game sprite atlas for Math Galaxy, glossy polished illustrated 3D sci-fi matching the two user references (blue white fighter and purple cyclops / orange machine). Transparent background. Precisely 3 columns by 2 rows equal cells, each object centered wholly inside own cell with ample transparent padding, no overlap. Top row: three DIFFERENT heroic spaceships facing RIGHT in side three-quarter view, white blue cyan agile fighter, white gold heavy fighter, silver violet interceptor. Bottom row: three DIFFERENT monsters facing LEFT, purple spherical single-eyed spiky alien with fangs, orange armored spherical robot with glowing orange central eye and cannons, turquoise crystalline alien with multiple eyes and ice horns. Highly readable silhouettes, sharp metallic details, rich rim lighting. No text, no UI, no borders, no shadows outside silhouettes, no background.

Transparency edit prompt:
Remove ALL colored and black background and background glow, replacing with actual alpha transparency. Preserve the six objects and their exact 3x2 placement and dimensions and detailed artwork. Keep each object strictly within its own equal cell, shrink slightly to prevent crossing cell edges. No backdrop of any kind, no gradients, no opaque background. Production transparent game sprites.

Integration: SpaceScene.gd selects the fighter by equipped hangar skin and cycles monsters by world and defeated enemy count. Damage numbers represent enemy HP (1 per hit) and shield damage (20). Buttons are drawn in code so borders stay sharp at different window sizes.

## Isolated sprites, revision 2

All six final sprites are now generated as individual transparent assets from the source atlas, rather than sliced from touching atlas cells. This prevents fragments of adjacent characters and avoids clipping noses, wings, horns or cannons. The atlas remains a source reference only.

Built-in image_gen edit prompts (one call per subject):
- Extract ONLY the TOP LEFT white blue cyan fighter / TOP CENTER gold white heavy fighter / TOP RIGHT silver violet interceptor. Keep its design and right-facing three-quarter view and colored engine exhaust. Center the entire ship with 10% clear padding on EVERY side; all nose and wings completely visible. No other ships, no monsters, no fragments of other objects, no backdrop or background glow. Single ship only, fully transparent alpha background.
- Extract ONLY the BOTTOM LEFT purple single eye spiky alien / BOTTOM CENTER orange armored robot monster / BOTTOM RIGHT turquoise crystalline many-eyed monster. Keep its design and left-facing view. Entire monster centered with generous clear padding, horns and cannons completely visible. No other objects, no ships, no fragments of neighbors, no background or backdrop glow. Single monster only, fully transparent alpha background.

Ship engine exhaust is painted into each sprite. SpaceScene only adds a subtle cyan/gold/violet pulsing light, without drawing a second polygon flame. Native Godot animation remains available without GIF playback.


## Fleet expansion, 2026-10-31

27 new isolated sprites generated using the built-in `image_gen` tool, one call
per asset with `transparent_background: true`. Destinations: `ship_1.png` through
`ship_10.png`, `weapon_1.png` through `weapon_7.png`, `monster_1.png` through
`monster_10.png` in this directory. Full prompt subjects and the shared prompt
are recorded in `fleet_expansion_generation.json`. Generated alpha is preserved.

These override the historical integration description above: the hull and
weapon are equipped independently; one monster is chosen at mission start from
a difficulty pool, HP persists across phases, and damage/armor follow
`FleetBalance.gd`. Existing three hulls and three weapon effects remain available.


## Animation coverage

All 13 hulls use the engine shader both in battle and hangar previews. The shader
finds bright saturated exhaust throughout the left side, rather than a fixed
pair of nozzle coordinates. Painted flames ripple and pulse without adding a
second detached flame sprite.

All 13 monsters have explicit motion profiles in `SpaceScene.MONSTER_MOTION`:
organic breathing, mechanical appendage movement, crystal sway, soft-body and
tentacle ripples, or wing/tail flex. Body motion, charge squash, firing lunge and
recoil, impact flinch, flashes and persistent damage work for every species.
`tests/test_actor_animation.gd` checks all hulls and species through these states.
