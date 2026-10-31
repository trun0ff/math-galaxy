extends SceneTree
const L10N = preload("res://scripts/Localization.gd")
class TestMain extends "res://scripts/Main.gd":
	func save_progress() -> void: pass
func _initialize() -> void: call_deferred("run")
func fit_buttons(node: Node) -> void:
	for button in node.find_children("*", "Button", true, false):
		var caption := button.get_node_or_null("Caption")
		if caption != null and caption.autowrap_mode == TextServer.AUTOWRAP_OFF:
			assert(caption.get_minimum_size().x <= button.size.x-39, caption.text)
func run() -> void:
	var host := TestMain.new()
	root.add_child(host)
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.set_process(false)
	for language in ["en", "uk"]:
		L10N.apply_language(language)
		host.show_menu()
		await process_frame
		await process_frame
		fit_buttons(host)
		assert(host.find_child("GameLogo",true,false) != null)
		host.world = 2
		host.show_workshop()
		await process_frame
		await process_frame
		fit_buttons(host)
		host.start_mission()
		await process_frame
		await process_frame
		fit_buttons(host)
		assert(host.shield_label.text == "100%")
		var meter_center: float = host.shield_bar.get_global_rect().get_center().y
		var label_center: float = host.shield_label.get_global_rect().get_center().y
		assert(absf(meter_center-label_center) <= 1)
	L10N.apply_language("en")
	host.progress = {"coins":0,"missions":0,"skills":{}}
	host.save_writable = true
	host.show_hangar()
	await process_frame
	await process_frame
	var purchase: Button
	for button in host.find_children("*","Button",true,false):
		var caption := button.get_node_or_null("Caption")
		if caption != null and caption.text == "180 CRYSTALS": purchase = button
	assert(purchase != null and not purchase.disabled)
	purchase.pressed.emit()
	assert(host.get_node_or_null("GameNotice") != null)
	assert(host.progress.coins == 0 and not host.progress.rewards.owned.has("violet"))
	host.show_menu()
	host.progress.erase("parent_pin")
	host.open_parent()
	var panel: Control = host.get_children().back()
	for attempt in range(2):
		for digit in [1,2,3,4]:
			var event := InputEventKey.new()
			event.pressed = true
			event.unicode = 48+digit
			event.keycode = KEY_0+digit
			panel._unhandled_key_input(event)
		assert(panel.pin == "1234")
		assert(panel.pin_keypad.current_value == "••••")
		var enter := InputEventKey.new()
		enter.pressed = true
		enter.keycode = KEY_KP_ENTER
		panel._unhandled_key_input(enter)
		if attempt == 0: assert(panel.pin == "" and panel.pin_keypad.current_value == "")
	assert(panel.unlocked and host.progress.has("parent_pin"))
	host.free()
	print("UI sizing, purchase notice and PIN keyboard tests passed")
	quit()

