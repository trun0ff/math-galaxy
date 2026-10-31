extends RefCounted

const CATALOG = {
	"violet": {"name": "Violet hull", "cost": 180, "description": "Cosmetic ship colour"},
	"gold": {"name": "Golden hull", "cost": 300, "description": "Cosmetic ship colour"},
	"battery": {"name": "Energy reserve", "cost": 220, "description": "+15 starting hint energy (one upgrade)"},
	"repair": {"name": "Repair pulse", "cost": 260, "description": "Restore 15 shield once per mission (one upgrade)"}
}
const ACHIEVEMENTS = {"first": "First completed mission", "accurate": "At least 90% accuracy (10 answers)", "return": "Completed practice on 3 different days", "courage": "Returned to a difficult fact", "progress": "Improved personal accuracy"}

static func migrate(p: Dictionary) -> void:
	p["coins"] = maxi(0, int(p.get("coins", 0)))
	var r: Dictionary = p.get("rewards", {})
	for key in ["owned", "achievements", "days", "records"]:
		if not r.get(key) is Dictionary: r[key] = {}
	r["settled"] = maxi(int(r.get("settled", 0)), 0)
	r["equipped"] = str(r.get("equipped", "default"))
	p["rewards"] = r
	p["schema_version"] = maxi(13, int(p.get("schema_version", 0)))

static func purchase(p: Dictionary, id: String) -> bool:
	migrate(p)
	if not CATALOG.has(id) or p.rewards.owned.has(id): return false
	var cost: int = int(CATALOG[id].cost)
	if int(p.coins) < cost: return false
	p.coins = int(p.coins) - cost
	p.rewards.owned[id] = true
	return true

static func equip(p: Dictionary, id: String) -> bool:
	migrate(p)
	if id != "default" and (id not in ["violet", "gold"] or not p.rewards.owned.has(id)): return false
	p.rewards.equipped = id
	return true

static func settle(p: Dictionary, mission: int, won: bool, hits: int, misses: int, base: int, difficult: int, day: String, world: int) -> Dictionary:
	migrate(p)
	var r: Dictionary = p.rewards
	if mission <= int(r.settled): return {"amount": 0, "details": "Already settled"}
	r.settled = mission
	if not won: return {"amount": 0, "details": "No reward for an unfinished mission"}
	var amount := maxi(0, base) + 40
	var details := "Completion +40"
	var accuracy := float(hits) / maxi(1, hits + misses)
	var record: Dictionary = r.records.get(str(world), {})
	var improved := hits + misses >= 10 and record.has("accuracy") and accuracy > float(record.accuracy)
	if not r.days.has(day):
		r.days[day] = true
		amount += 30
		details += " | New practice day +30"
	if difficult > 0:
		amount += 25
		details += " | Difficult facts +25"
	if improved:
		amount += 30
		details += " | Accuracy progress +30"
	var eligible := {"first": true, "accurate": hits + misses >= 10 and accuracy >= 0.9, "return": r.days.size() >= 3, "courage": difficult > 0, "progress": improved}
	for id in eligible:
		if eligible[id] and not r.achievements.has(id):
			r.achievements[id] = true
			amount += 25
			details += " | " + str(ACHIEVEMENTS[id]) + " +25"
	if hits + misses >= 10: record["accuracy"] = maxf(float(record.get("accuracy", 0)), accuracy)
	record["hits"] = maxi(int(record.get("hits", 0)), hits)
	r.records[str(world)] = record
	p.coins = int(p.coins) + amount
	return {"amount": amount, "details": details}
