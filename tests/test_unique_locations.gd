extends SceneTree
const LOCATIONS = preload("res://scripts/WorldLocations.gd")
const P = preload("res://scripts/LearningProgression.gd")
const L10N = preload("res://scripts/Localization.gd")
func _initialize() -> void:
 var paths: Dictionary = {}
 var hashes: Dictionary = {}
 var names: Dictionary = {}
 var count: int = 0
 L10N.apply_language("uk")
 for world in P.WORLD_ORDER:
  assert(LOCATIONS.NAMES[world - 1].size() * 2 == P.levels(world).size())
  for level in range(0, P.levels(world).size(), 2):
   var path: String = LOCATIONS.asset_path(world, level)
   assert(not paths.has(path), "Location path reused: " + path)
   assert(FileAccess.file_exists(path), "Missing location art: " + path)
   var digest: String = FileAccess.get_sha256(path)
   assert(not hashes.has(digest), "Identical images reused: " + path)
   var texture: Texture2D = LOCATIONS.texture(world, level)
   assert(texture != null and not texture is AtlasTexture)
   assert(texture.get_width() >= 1000 and texture.get_height() >= 500)
   assert(texture.resource_path == path)
   assert(LOCATIONS.texture(world, level + 1) == texture, "Skill pair must share its location")
   var source: String = LOCATIONS.NAMES[world - 1][int(level / 2)]
   assert(LOCATIONS.title(world, level) != source, "Missing translation: " + source)
   assert(not names.has(source))
   paths[path] = true
   hashes[digest] = true
   names[source] = true
   count += 1
 assert(count == 56)
 print("Unique location tests passed: 56 distinct paintings, pair mappings and translations verified")
 quit()
