# Math Galaxy - Godot 4 Android prototype

This is a first **playable prototype**, not a polished release APK.

## Requirements
- Godot 4.3+ standard (GDScript), preferably recent stable Godot 4
- Desktop for initial testing; Android export templates + Android SDK / JDK 17 to create APK

## Run
1. Unzip this repository.
2. Open Godot Project Manager -> **Import** -> choose `project.godot`.
3. Open project and press **F6/F5** (Run Project).
4. Pick a world and press **START 5-MINUTE MISSION**.
5. Answer using on-screen digits + OK, or tap one of four choices.

## Android APK export
1. In Godot install matching **Export Templates** via Editor -> Manage Export Templates.
2. Set up Android SDK and Java (JDK 17) in Editor Settings -> Export -> Android, if required by your Godot version.
3. Project -> Export -> Add -> Android.
4. Choose an Android package identifier, for example `org.example.mathgalaxy` (change this for a published game).
5. **Export Project** to an APK. For local testing, use debug export.
6. Transfer the APK to your phone and install it (allow installation from trusted local source if Android asks).

Official guide: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html

## Prototype behavior
- All 5 worlds generate random examples (world 5 generates only exact integer quotients).
- Mission duration: 300 seconds, with five phases (35/50/150/45/20 seconds).
- Per-question time limit by world: 8/20/35/60/45 seconds, +8 seconds in workshop.
- 25% multiple-choice, 75% number entry, randomly distributed.
- Wrong, skipped or timed-out answers damage shield by 20; correct answer restores 5.
- Shield automatically restores to 30 after depletion so play is never blocked.
- Hints cost 25 energy and add 8 seconds; this is a simplified teaching aid.
- Missed questions have a chance to reappear in the boss phase.
- Progress and earned crystals are saved to `user://math_galaxy_progress.json` after each mission.

## Known limitations and next milestones
- Graphic characters are drawn from polygons, not finalized assets. No audio yet.
- The workshop currently offers hints, not full interactive decomposition steps.
- Boss is represented by phase changes, not yet a distinct animated boss.
- The learning selector uses a basic error-weighted heuristic; spaced repetition and separate mastery for choice vs free-input need a later implementation.
- Progress saves on mission end only. Mid-mission exit saves what has been earned thus far.
- Only English UI in this initial prototype; Ukrainian and Russian localization can be added.
- Device and Android APK runtime testing have not been performed in this environment.

## Project files
- `scripts/Main.gd`: UI, mission lifecycle, shield, timer, persistence
- `scripts/MathEngine.gd`: math problems, options, hints
- `scripts/SpaceScene.gd`: animated ship, aliens, laser and damage effects
- `scenes/Main.tscn`: entry scene
