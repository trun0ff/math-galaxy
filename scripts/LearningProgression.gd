extends RefCounted

class_name LearningProgression

const L10N = preload("res://scripts/Localization.gd")


const TAXONOMY = preload("res://scripts/SkillTaxonomy.gd")
const WORLD_ORDER = [1, 6, 2, 7, 3, 8, 4, 5]
const TRACKS = [
 ["Table of 2", "Table of 3", "Table of 4", "Table of 5", "Table of 6", "Table of 7", "Table of 8", "Table of 9", "Mixed tables", "Final challenge"],
 ["No carrying", "Carrying", "Mixed practice", "Final challenge"],
 ["No carrying", "One carry", "Multiple carries", "Final challenge"],
 ["No carrying", "Carrying", "Mixed practice", "Final challenge"],
 ["One-digit divisor", "Two-digit divisor", "Mixed practice", "Final challenge"],
 ["Divide by 2", "Divide by 3", "Divide by 4", "Divide by 5", "Divide by 6", "Divide by 7", "Divide by 8", "Divide by 9", "Mixed practice", "Final challenge"],
 ["Divide by 2", "Divide by 3", "Divide by 4", "Divide by 5", "Divide by 6", "Divide by 7", "Divide by 8", "Divide by 9", "Mixed practice", "Final challenge"],
 ["Divide by 2", "Divide by 3", "Divide by 4", "Divide by 5", "Divide by 6", "Divide by 7", "Divide by 8", "Divide by 9", "Mixed practice", "Final challenge"]
]

static func levels(world: int) -> Array:
 var translated: Array = []
 for title in TRACKS[clampi(world, 1, 8) - 1]:
  translated.append(L10N.text(title) + " · " + L10N.text("Choose · 5 seconds"))
  translated.append(L10N.text(title) + " · " + L10N.text("Enter · reinforcement"))
 return translated

static func input_mode(level: int) -> String:
 return "choices" if level % 2 == 0 else "numeric"

static func previous_world(world: int) -> int:
 var index: int = WORLD_ORDER.find(world)
 return WORLD_ORDER[index - 1] if index > 0 else 0

static func id_for(world: int, level: int) -> String:
 return "%d:%d" % [world, level]

static func is_unlocked(progress: Dictionary, world: int, level: int) -> bool:
 if level < 0 or level >= levels(world).size(): return false
 if level == 0:
  if bool(progress.get("parent_settings", {}).get("independent_worlds", false)): return true
  if world == 1: return true
  if int(progress.get("legacy_unlocked_world", 1)) >= world: return true
  return bool(progress.get("completed_levels", {}).get(id_for(previous_world(world), levels(previous_world(world)).size() - 1), false))
 return bool(progress.get("completed_levels", {}).get(id_for(world, level - 1), false))

# Continue after the furthest victory in campaign order, ignoring independent unlocks.
static func continue_target(progress: Dictionary) -> Dictionary:
 var route: Array[Dictionary] = []
 var last_completed: int = -1
 for world in WORLD_ORDER:
  for level in range(levels(world).size()):
   route.append({"world": world, "level": level})
   if bool(progress.get("completed_levels", {}).get(id_for(world, level), false)):
    last_completed = route.size() - 1
 for index in range(last_completed + 1, route.size()):
  var target: Dictionary = route[index]
  if is_unlocked(progress, int(target.world), int(target.level)):
   return target
 return {}

static func requirement(progress: Dictionary, world: int, level: int) -> String:
 if is_unlocked(progress, world, level): return L10N.text("Available")
 if level == 0: return L10N.text("Complete World %d final challenge") % WORLD_ORDER.find(world)
 return L10N.text("Complete %s") % levels(world)[level - 1]

static func matches(world: int, level: int, q: Dictionary) -> bool:
 level = int(level / 2)
 if world >= 6:
  return level >= 8 or int(q.get("b", 0)) == level + 2
 if world == 1:
  if level < 8: return int(q.get("a", 0)) == level + 2 or int(q.get("b", 0)) == level + 2
  return true
 var key: String = TAXONOMY.key_for(q)
 if world == 2: return level >= 2 or key == ("w2_no_carry" if level == 0 else "w2_carry")
 if world == 3: return level >= 3 or key == ["w3_no_carry", "w3_carry", "w3_multi_carry"][level]
 if world == 4: return level >= 2 or key == ("w4_no_carry" if level == 0 else "w4_carry")
 return level >= 2 or key == ("w5_one_digit_divisor" if level == 0 else "w5_two_digit_divisor")

static func is_final(world: int, level: int) -> bool:
 return level == levels(world).size() - 1

static func practice_target(progress: Dictionary, world: int) -> int:
 for i in range(levels(world).size()):
  if not bool(progress.get("completed_levels", {}).get(id_for(world, i), false)):
   return i
 return levels(world).size() - 1

static func generate(world: int, level: int) -> Dictionary:
 # The initial tables and taxonomy buckets are reachable by construction.
 for attempt in range(2000):
  var q: Dictionary = MathEngine.generate(world)
  if matches(world, level, q): return q
 # Fallback builds a matching example rather than silently using a wrong skill.
 if world == 1 and int(level / 2) < 8:
  var b: int = randi_range(2, 9)
  var a: int = int(level / 2) + 2
  return {"a": a, "b": b, "answer": a * b, "sign": "×", "world": 1, "key": "1_%d_%d" % [a, b]}
 # Keep searching rather than silently select an incorrect taxonomy skill.
 while true:
  var candidate: Dictionary = MathEngine.generate(world)
  if matches(world, level, candidate): return candidate
 return {}

static func review_world(world: int, level: int) -> int:
 if WORLD_ORDER.find(world) <= 0 or level == 0:
  return 0
 return WORLD_ORDER[randi_range(0, WORLD_ORDER.find(world) - 1)]

static func required_evidence(world: int, level: int) -> String:
 if input_mode(level) == "choices": return L10N.text("5 correct choices, 3 distinct examples and 2 missions")
 return L10N.text("8 independent answers, including 2 boss answers, 5 distinct examples and 2 missions") if is_final(world, level) else L10N.text("5 independent answers, 3 distinct examples and 2 missions")


static func record(progress: Dictionary, world: int, level: int, q: Dictionary, correct: bool, reason: String, mode: String, hinted: bool, boss_phase: bool = false) -> void:
 var key: String = id_for(world, level)
 var evidence: Dictionary = progress.get("level_evidence", {})
 var data: Dictionary = evidence.get(key, {}).duplicate(true)
 var independent: bool = correct and reason == "answer" and mode == input_mode(level) and not hinted
 if int(q.get("world", 0)) != world or not matches(world, level, q): return
 data["independent"] = int(data.get("independent", 0)) + int(independent)
 if boss_phase and independent:
  data["boss_independent"] = int(data.get("boss_independent", 0)) + 1
  var boss_distinct: Dictionary = data.get("boss_distinct", {})
  boss_distinct[str(q.get("key", ""))] = true
  data["boss_distinct"] = boss_distinct
 data["errors"] = int(data.get("errors", 0)) + int(not correct)
 var distinct: Dictionary = data.get("distinct", {})
 if independent: distinct[str(q.get("key", ""))] = true
 data["distinct"] = distinct
 var missions: Dictionary = data.get("missions", {})
 if independent: missions[str(progress.get("mission_sequence", 0))] = true
 data["missions"] = missions
 evidence[key] = data
 progress["level_evidence"] = evidence

static func can_pass(progress: Dictionary, world: int, level: int) -> bool:
 var data: Dictionary = progress.get("level_evidence", {}).get(id_for(world, level), {})
 var final_level: bool = is_final(world, level)
 var required: int = 8 if final_level else 5
 var distinct_required: int = 5 if final_level else 3
 var base: bool = int(data.get("independent", 0)) >= required and data.get("distinct", {}).size() >= distinct_required and data.get("missions", {}).size() >= 2 and int(data.get("errors", 0)) <= int(data.get("independent", 0))
 if not base: return false
 return not final_level or (int(data.get("boss_independent", 0)) >= 2 and data.get("boss_distinct", {}).size() >= 2)

static func complete(progress: Dictionary, world: int, level: int) -> bool:
 if not can_pass(progress, world, level): return false
 var completed: Dictionary = progress.get("completed_levels", {})
 completed[id_for(world, level)] = true
 progress["completed_levels"] = completed
 return true


# Map travel is a game reward. Mastery remains independently measured by can_pass.
static func complete_victory(progress: Dictionary, world: int, level: int, hits: int, monster_hp: int, shield: int, practice: bool = false) -> bool:
 if practice or monster_hp > 0 or shield <= 0 or hits < (12 if is_final(world, level) else 10): return false
 if not is_unlocked(progress, world, level): return false
 var completed: Dictionary = progress.get("completed_levels", {})
 completed[id_for(world, level)] = true
 progress["completed_levels"] = completed
 return true

static func restore_recorded_victories(progress: Dictionary) -> void:
 # Old history contains no practice flag. Only full, won encounters qualify.
 var completed: Dictionary = progress.get("completed_levels", {})
 for row in progress.get("mission_history", []):
  if not bool(row.get("won", false)) or bool(row.get("practice", false)): continue
  var world := int(row.get("world", 0))
  var level := int(row.get("level", -1))
  if world < 1 or world > 8 or level < 0 or level >= levels(world).size(): continue
  if int(row.get("hits", 0)) < (12 if is_final(world, level) else 10): continue
  completed[id_for(world, level)] = true
 progress["completed_levels"] = completed
