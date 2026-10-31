extends SceneTree

const P = preload("res://scripts/LearningProgression.gd")

func _initialize() -> void:
 var progress: Dictionary = {"completed_levels": {}, "level_evidence": {}, "legacy_unlocked_world": 1, "mission_sequence": 1}
 assert(P.is_unlocked(progress, 1, 0))
 assert(not P.is_unlocked(progress, 1, 1))
 assert(not P.is_unlocked(progress, 5, P.levels(5).size()))
 assert(P.practice_target(progress, 1) == 0)
 assert(not P.can_pass(progress, 1, 0))
 for world in P.WORLD_ORDER:
  for level in range(P.levels(world).size()):
   for n in range(12):
    var q: Dictionary = P.generate(world, level)
    assert(int(q["world"]) == world)
    assert(P.matches(world, level, q))
 var q: Dictionary = P.generate(1, 0)
 P.record(progress, 1, 0, q, true, "answer", "choices", false)
 assert(not P.can_pass(progress, 1, 0))
 for mission in range(1, 3):
  progress["mission_sequence"] = mission
  for b in range(2, 9):
   var example: Dictionary = {"a": 2, "b": b, "answer": 2*b, "sign": "×", "world": 1, "key": "1_2_%d" % b}
   P.record(progress, 1, 0, example, true, "answer", "choices", false)
 assert(P.can_pass(progress, 1, 0))
 assert(P.complete(progress, 1, 0))
 assert(P.is_unlocked(progress, 1, 1))
 assert(P.practice_target(progress, 1) == 1)
 progress["completed_levels"]["1:19"] = true
 assert(P.is_unlocked(progress, 6, 0))
 assert(P.is_unlocked({"legacy_unlocked_world": 4}, 4, 0))
 for world in P.WORLD_ORDER:
  for level in range(0, P.levels(world).size(), 2):
   assert(P.input_mode(level) == "choices")
   assert(P.input_mode(level + 1) == "numeric")
   for n in range(30):
    var example: Dictionary = P.generate(world, level)
    assert(P.matches(world, level + 1, example))
    if world >= 5:
     assert(example.sign == "÷")
     assert(example.a == example.b * example.answer)
 var save = preload("res://scripts/SaveManager.gd")
 var migrated: Dictionary = save.migrate({"schema_version": 13, "skills": {}, "completed_levels": {"2:1": true}})
 assert(migrated.completed_levels.get("2:2", false))
 assert(migrated.completed_levels.get("2:3", false))
 assert(save.migrate(migrated) == migrated)
 print("Progression tests passed")
 quit(0)
