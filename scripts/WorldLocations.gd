extends RefCounted
class_name WorldLocations

const L10N = preload("res://scripts/Localization.gd")
const NAMES = [
 [
  "Thunder Gate",
  "Cloud Observatory",
  "Storm Islands",
  "Lightning Harbor",
  "Sky Citadel",
  "Beacon Cliffs",
  "Tempest Library",
  "Electric Falls",
  "Ionosphere Gardens",
  "Stormheart Fortress"
 ],
 [
  "Copper Dunes",
  "Gear Canyon",
  "Sand Observatory",
  "Engine Ruins"
 ],
 [
  "Crystal Gate",
  "Sapphire Valley",
  "Prism Caverns",
  "Frozen Arches"
 ],
 [
  "Titan Spaceport",
  "Golden Bridges",
  "Orbital Gardens",
  "Tower District"
 ],
 [
  "Violet Rift",
  "Gravity Station",
  "Asteroid Passage",
  "Event Horizon"
 ],
 [
  "Coral Gateway",
  "Moonlit Lagoon",
  "Tidal Observatory",
  "Sapphire Reefs",
  "Ocean Sanctuary",
  "Waterfall Isles",
  "Pearl Caverns",
  "Abyssal Lanterns",
  "Whirlpool Passage",
  "Tidal Palace"
 ],
 [
  "Emerald Terrace",
  "Floating Gardens",
  "Aurora Bridge",
  "Luminous Grove",
  "Sky Observatory",
  "Starlily Lake",
  "Canopy Ruins",
  "Prism Waterfalls",
  "Moonseed Orchard",
  "Aurora Crown"
 ],
 [
  "Amber Canyon",
  "Obsidian Islands",
  "Solar Towers",
  "Forge Harbor",
  "Sunfire Citadel",
  "Lava Gardens",
  "Ember Caverns",
  "Helios Foundry",
  "Corona Bridge",
  "Heart of the Sun"
 ]
]
static var textures: Dictionary = {}
static var panoramas: Dictionary = {}
static var cached_world: int = 0

static func location_index(world: int, level: int) -> int:
 assert(world >= 1 and world <= NAMES.size(), "Invalid location world")
 var index: int = int(level / 2)
 assert(level >= 0 and index < NAMES[world - 1].size(), "Invalid location level")
 return index

static func title(world: int, level: int) -> String:
 return L10N.text(NAMES[world - 1][location_index(world, level)])

static func asset_path(world: int, level: int) -> String:
 return "res://assets/locations/world_%d/location_%02d.png" % [world, location_index(world, level) + 1]

static func texture(world: int, level: int) -> Texture2D:
 # Release the previous world's cached locations when travelling to another world.
 # Active UI nodes retain their own resources until the screen is replaced.
 if cached_world != world:
  textures.clear()
  cached_world = world
 var path: String = asset_path(world, level)
 if not textures.has(path):
  textures[path] = load(path)
 assert(textures[path] != null, "Missing dedicated location artwork: " + path)
 return textures[path]

static func world_portrait(world: int) -> AtlasTexture:
 # World portraits keep using the overview painting, independent of location art.
 if not panoramas.has(world):
  panoramas[world] = load("res://assets/locations/world_%d.png" % world)
 var panorama: Texture2D = panoramas[world]
 var portrait := AtlasTexture.new()
 portrait.atlas = panorama
 var edge: float = panorama.get_height()
 portrait.region = Rect2(clampf(panorama.get_width() * 0.74 - edge * 0.5, 0, panorama.get_width() - edge), 0, edge, edge)
 return portrait
