extends TextureRect
const FLEET = preload("res://scripts/FleetBalance.gd")
var elapsed := 0.0
func _process(delta: float) -> void:
	elapsed += delta
	if material is ShaderMaterial:
		material.set_shader_parameter("clock", elapsed)
		if texture != null:
			var id := texture.resource_path.get_file().get_basename()
			id = {"fighter_cyan": "default", "fighter_gold": "gold", "fighter_violet": "violet"}.get(id, id)
			FLEET.configure_engine(material, FLEET.ship_index(id))
