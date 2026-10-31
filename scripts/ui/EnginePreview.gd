extends TextureRect
var elapsed := 0.0
func _process(delta: float) -> void:
	elapsed += delta
	if material is ShaderMaterial:
		material.set_shader_parameter("clock", elapsed)
