extends RefCounted
## Fixed encounter strength follows the curriculum, never the player's wallet.
const SHIP_IDS = ["default", "violet", "gold", "ship_1", "ship_2", "ship_3", "ship_4", "ship_5", "ship_6", "ship_7", "ship_8", "ship_9", "ship_10"]
const WEAPON_IDS = ["laser", "machine_gun", "lightning", "weapon_1", "weapon_2", "weapon_3", "weapon_4", "weapon_5", "weapon_6", "weapon_7"]
const SHIP_NAMES = ["Scout", "Violet interceptor", "Golden guardian", "Mint swift", "Ember falcon", "Iron turtle", "Azure lancer", "Emerald crescent", "Crimson hammer", "Solar sail", "Night manta", "Copper citadel", "Star phoenix"]
const WEAPON_NAMES = ["Cyan laser", "Burst cannon", "Violet lightning", "Twin pulse", "Plasma launcher", "Cryo beam", "Railgun", "Solar ray", "Gravity projector", "Nova cannon"]
const SHIP_COSTS = [0, 1200, 1800, 2600, 3500, 4500, 5700, 7100, 8700, 10500, 12500, 14800, 17500]
const WEAPON_COSTS = [0, 1000, 1900, 3000, 4400, 6000, 7900, 10100, 12600, 15500]
const POWER = [1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 8]
const ARMOR = [0, 1, 3, 2, 3, 5, 4, 5, 7, 6, 7, 8, 9]
const BONUS = [0, 5, 8, 12, 18, 15, 25, 32, 28, 40, 48, 52, 60]
const DAMAGE = [10, 13, 16, 20, 25, 31, 38, 46, 55, 66]
const DRAW = [1, 2, 2, 3, 4, 4, 5, 6, 7, 8]
const MODES = ["laser", "machine_gun", "lightning", "pulse", "plasma", "cryo", "rail", "solar", "gravity", "nova"]
const COLORS = ["32cfff", "ffba32", "b657ff", "58ffc1", "ff963f", "a5eaff", "ff536c", "ffe582", "ba77ff", "e9faff"]
const SHIP_TINTS = ["32cfff", "b657ff", "ffba32", "58ffc1", "ff963f", "ff536c", "72c4ff", "58ffc1", "ff536c", "ffe582", "8585ff", "59d6ce", "d6a5ff"]
const MONSTER_NAMES = ["Cyclops", "Mech", "Crystal beast", "Moon slug", "Magma crab", "Nebula jelly", "Dusk bat", "Iron beetle", "Ice golem", "Star kraken", "Sun scarab", "Void dragon", "Leviathan"]

static func ship_index(id: String) -> int:
	return maxi(0, SHIP_IDS.find(id))

static func weapon_index(id: String) -> int:
	return maxi(0, WEAPON_IDS.find(id))

static func ship_texture(id: String) -> Texture2D:
	var path := "res://assets/battle/%s.png" % id
	if id in ["default", "gold", "violet"]: path = "res://assets/battle/fighter_%s.png" % ("cyan" if id == "default" else id)
	return load(path)

static func monster_texture(index: int) -> Texture2D:
	var file: String = ["monster_cyclops", "monster_mech", "monster_crystal"][index] if index < 3 else "monster_%d" % (index - 2)
	return load("res://assets/battle/%s.png" % file)

static func raw_damage(ship: int, weapon: int) -> int:
	return int(round(DAMAGE[weapon] * (1.0 + BONUS[ship] / 100.0)))

static func encounter(world: int, level: int, minimum: int) -> Dictionary:
	var order := [1, 6, 2, 7, 3, 8, 4, 5]
	var ordinal := level
	for w in order:
		if w == world: break
		ordinal += 20 if w in [1, 6, 7, 8] else 8
	# Conservative 360 crystals per sublevel (two evidence missions); reserve 20% for upgrades.
	var budget := int(ordinal * 360 * 0.8)
	var best := 10
	for s in range(SHIP_IDS.size()):
		for w in range(WEAPON_IDS.size()):
			if DRAW[w] <= POWER[s] and SHIP_COSTS[s] + WEAPON_COSTS[w] <= budget:
				best = maxi(best, raw_damage(s, w))
	return {"hp": best * minimum, "minimum": minimum, "budget": budget, "reference_damage": best, "tier": mini(4, int(ordinal / 23))}

static func damage(ship: int, weapon: int, encounter_data: Dictionary) -> int:
	# Focus assistance keeps starter equipment viable: at most 1.8x the ideal answers.
	var minimum: int = encounter_data.minimum
	var floor_damage := int(ceil(float(encounter_data.hp) / ceil(minimum * 1.8)))
	return clampi(raw_damage(ship, weapon), floor_damage, int(encounter_data.reference_damage))

static func monster_pool(tier: int) -> Array:
	var pools := [[0, 3, 5, 6], [0, 1, 3, 4, 5, 6, 7], [1, 2, 4, 7, 8, 9], [2, 7, 8, 9, 10, 11], [2, 8, 9, 10, 11, 12]]
	return pools[clampi(tier, 0, 4)]
