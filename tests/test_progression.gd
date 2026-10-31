extends SceneTree

const P = preload("res://scripts/LearningProgression.gd")

func _initialize() -> void:
 var progress: Dictionary = {"completed_levels": {}, "level_evidence": {}, "legacy_unlocked_world": 1, "mission_sequence": 1}
 assert(P.is_unlocked(progress, 1, 0))
 assert(not P.is_unlocked(progress, 1, 1))
 assert(not P.is_unlocked(progress, 5, P.levels(5).size()))
 assert(P.practice_target(progress, 1) == 0)
 assert(not P.can_pass(progress, 1, 0))
 for world in range(1, 6):
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
   P.record(progress, 1, 0, example, true, "answer", "numeric", false)
 assert(P.can_pass(progress, 1, 0))
 assert(P.complete(progress, 1, 0))
 assert(P.is_unlocked(progress, 1, 1))
 assert(P.practice_target(progress, 1) == 1)
 progress["completed_levels"]["1:9"] = true
 assert(P.is_unlocked(progress, 2, 0))
 assert(P.is_unlocked({"legacy_unlocked_world": 4}, 4, 0))
 print("Progression tests passed")
 quit(0)
