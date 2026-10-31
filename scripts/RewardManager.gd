extends RefCounted

const L10N = preload("res://scripts/Localization.gd")

const FLEET = preload("res://scripts/FleetBalance.gd")
static var CATALOG: Dictionary = build_catalog()

static func build_catalog() -> Dictionary:
	var result := {
		"battery": {"name": "Energy reserve", "cost": 2200, "description": "+15 starting hint energy (one upgrade)", "kind": "upgrade"},
		"repair": {"name": "Repair pulse", "cost": 2600, "description": "Restore 15 shield once per mission (one upgrade)", "kind": "upgrade"}
	}
	for i in range(1, FLEET.SHIP_IDS.size()):
		result[FLEET.SHIP_IDS[i]] = {"name": FLEET.SHIP_NAMES[i], "cost": FLEET.SHIP_COSTS[i], "kind": "ship"}
	for i in range(1, FLEET.WEAPON_IDS.size()):
		result[FLEET.WEAPON_IDS[i]] = {"name": FLEET.WEAPON_NAMES[i], "cost": FLEET.WEAPON_COSTS[i], "kind": "weapon"}
	return result

const ACHIEVEMENTS = {"first": "First completed mission", "accurate": "At least 90% accuracy (10 answers)", "return": "Completed practice on 3 different days", "courage": "Returned to a difficult fact", "progress": "Improved personal accuracy"}

static func migrate(p: Dictionary) -> void:
	p["coins"] = maxi(0, int(p.get("coins", 0)))
	var r: Dictionary = p.get("rewards", {})
	for key in ["owned", "achievements", "days", "records"]:
		if not r.get(key) is Dictionary: r[key] = {}
	r["settled"] = maxi(int(r.get("settled", 0)), 0)
	r["equipped"] = str(r.get("equipped", "default"))
	# Repair stale selections without removing legacy purchases.
	if r.equipped != "default" and (not FLEET.SHIP_IDS.has(r.equipped) or not r.owned.has(r.equipped)): r.equipped = "default"
	if not r.has("weapon"):
		# Legacy hull purchases included their signature weapon.
		if r.owned.has("gold"): r.owned["machine_gun"] = true
		if r.owned.has("violet"): r.owned["lightning"] = true
		r["weapon"] = "machine_gun" if r.equipped == "gold" else "lightning" if r.equipped == "violet" else "laser"
	r["weapon"] = str(r.get("weapon", "laser"))
	if r.weapon != "laser" and (not FLEET.WEAPON_IDS.has(r.weapon) or not r.owned.has(r.weapon)): r.weapon = "laser"
	if FLEET.DRAW[FLEET.weapon_index(r.weapon)] > FLEET.POWER[FLEET.ship_index(r.equipped)]: r.weapon = "laser"
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
	if FLEET.WEAPON_IDS.has(id):
		if id != "laser" and not p.rewards.owned.has(id): return false
		if FLEET.DRAW[FLEET.weapon_index(id)] > FLEET.POWER[FLEET.ship_index(p.rewards.equipped)]: return false
		p.rewards.weapon = id
		return true
	if not FLEET.SHIP_IDS.has(id) or (id != "default" and not p.rewards.owned.has(id)): return false
	p.rewards.equipped = id
	if FLEET.DRAW[FLEET.weapon_index(p.rewards.weapon)] > FLEET.POWER[FLEET.ship_index(id)]: p.rewards.weapon = "laser"
	return true

static func settle(p: Dictionary, mission: int, won: bool, hits: int, misses: int, base: int, difficult: int, day: String, world: int) -> Dictionary:
	migrate(p)
	var r: Dictionary = p.rewards
	if mission <= int(r.settled): return {"amount": 0, "details": L10N.text("Already settled")}
	r.settled = mission
	if not won: return {"amount": 0, "details": L10N.text("No reward for an unfinished mission")}
	var amount := maxi(0, base) + 40
	var details := L10N.text("Completion +40")
	var accuracy := float(hits) / maxi(1, hits + misses)
	var record: Dictionary = r.records.get(str(world), {})
	var improved := hits + misses >= 10 and record.has("accuracy") and accuracy > float(record.accuracy)
	if not r.days.has(day):
		r.days[day] = true
		amount += 30
		details += L10N.text(" | New practice day +30")
	if difficult > 0:
		amount += 25
		details += L10N.text(" | Difficult facts +25")
	if improved:
		amount += 30
		details += L10N.text(" | Accuracy progress +30")
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
