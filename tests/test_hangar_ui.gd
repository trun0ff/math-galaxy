extends SceneTree
const MAIN = preload("res://scripts/Main.gd")
const L10N = preload("res://scripts/Localization.gd")
class TestMain extends "res://scripts/Main.gd":
	func save_progress() -> void:
		pass

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var host := TestMain.new()
	root.add_child(host)
	host.set_process(false)
	for language in ["en", "uk"]:
		L10N.apply_language(language)
		host.show_menu()
		await process_frame
		await process_frame
		var flag: Button = host.find_child("Language_" + language, true, false)
		assert(flag != null and flag.tooltip_text != "")
		for button in host.main_box.find_children("*", "Button", true, false):
			var caption := button.get_node_or_null("Caption")
			if caption != null and caption.text.contains("✦"):
				assert(button.size.x >= caption.get_minimum_size().x + 60)
		host.show_hangar()
		await process_frame
		await process_frame
		for id in ["default", "gold", "violet"]:
			var preview: TextureRect = host.find_child("HullPreview_" + id, true, false)
			assert(preview != null and preview.texture != null)
		var tip: Label = host.find_child("HangarTip", true, false)
		assert(tip.text.begins_with("1 / 6"))
		var tip_row := tip.get_parent()
		tip_row.get_child(2).pressed.emit()
		assert(tip.text.begins_with("2 / 6"))
		tip_row.get_child(0).pressed.emit()
		assert(tip.text.begins_with("1 / 6"))
		tip_row.get_child(0).pressed.emit()
		assert(tip.text.begins_with("6 / 6"))
		tip_row.get_child(2).pressed.emit()
		assert(host.main_box.size.x <= 1280)
	host.free()
	L10N.apply_language("en")
	print("Hangar UI and language button tests passed")
	quit()
