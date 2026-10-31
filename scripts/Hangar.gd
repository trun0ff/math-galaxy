extends RefCounted

const L10N = preload("res://scripts/Localization.gd")

const REWARDS = preload("res://scripts/RewardManager.gd")

static func show(host: Control, notice: String = "") -> void:
	REWARDS.migrate(host.progress)
	host.screen = "hangar"
	var root: VBoxContainer = host.build_root(host.MENU_GALAXY)
	root.add_child(host.make_button(L10N.text("◀ GALAXY"), host.show_menu, Color("425d88"), 180, 48, 20))
	root.add_child(host.make_label(L10N.text("HANGAR  •  %d CRYSTALS") % int(host.progress.coins), 34, Color("84d8ff")))
	if not notice.is_empty(): root.add_child(host.make_label(notice, 20, Color("ffd85b")))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	scroll.add_child(content)
	var hulls := HBoxContainer.new()
	hulls.add_theme_constant_override("separation", 18)
	content.add_child(hulls)
	for id in ["default", "gold", "violet"]:
		var hull_id: String = id
		var accent: Color = Color("38cfff") if id == "default" else Color("ffc552") if id == "gold" else Color("b877ff")
		var panel := PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.add_theme_stylebox_override("panel", host.space_panel(Color("091831"), accent, 16, 0.18))
		hulls.add_child(panel)
		var card := VBoxContainer.new()
		card.add_theme_constant_override("separation", 8)
		panel.add_child(card)
		var title: String = "Original hull" if id == "default" else str(REWARDS.CATALOG[id].name)
		card.add_child(host.make_label(L10N.text(title), 24, accent))
		var preview := TextureRect.new()
		preview.name = "HullPreview_" + id
		preview.set_script(preload("res://scripts/ui/EnginePreview.gd"))
		var engine_material := ShaderMaterial.new()
		engine_material.shader = preload("res://assets/shaders/ship_engine.gdshader")
		engine_material.set_shader_parameter("engine_color", accent)
		preview.material = engine_material
		preview.texture = load("res://assets/battle/fighter_" + ("cyan" if id == "default" else id) + ".png")
		preview.custom_minimum_size = Vector2(220, 155)
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		card.add_child(preview)
		var detail: String = "Scout • Cyan laser" if id == "default" else "Heavy hull • 5-round burst" if id == "gold" else "Interceptor • Violet lightning"
		card.add_child(host.make_label(L10N.text(detail), 17, Color("b3cbe7")))
		var equipped: bool = host.progress.rewards.equipped == id
		var owned: bool = id == "default" or host.progress.rewards.owned.has(id)
		var text: String = L10N.text("EQUIPPED") if equipped else L10N.text("EQUIP") if owned else L10N.text("%d CRYSTALS") % int(REWARDS.CATALOG[id].cost)
		var button: Button = host.make_button(text, func():
			if hull_id == "default": host.equip_hangar(hull_id)
			else: host.buy_hangar(hull_id)
		, accent, 220, 48, 18)
		button.disabled = equipped
		card.add_child(button)
	var upgrades := HBoxContainer.new()
	upgrades.add_theme_constant_override("separation", 18)
	content.add_child(upgrades)
	for id in ["battery", "repair"]:
		var upgrade_id: String = id
		var item: Dictionary = REWARDS.CATALOG[id]
		var panel := PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.add_theme_stylebox_override("panel", host.space_panel(Color("101b34"), Color("427dc0")))
		upgrades.add_child(panel)
		var card := VBoxContainer.new()
		panel.add_child(card)
		card.add_child(host.make_label(("ϟ  " if id == "battery" else "✚  ") + L10N.text(item.name), 24, Color("84d8ff")))
		var description: Label = host.make_label(L10N.text(item.description), 18)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_child(description)
		var owned: bool = host.progress.rewards.owned.has(id)
		var button: Button = host.make_button(L10N.text("OWNED") if owned else L10N.text("%d CRYSTALS") % int(item.cost), func(): host.buy_hangar(upgrade_id), Color("2865ad"), 220, 46, 18)
		button.disabled = owned
		card.add_child(button)
	var details := VBoxContainer.new()
	details.visible = false
	content.add_child(host.make_button(L10N.text("ACHIEVEMENTS  (+25 each, once)") + "  ▾", func(): details.visible = not details.visible, Color("425d88"), 340, 48, 19))
	content.add_child(details)
	for id in REWARDS.ACHIEVEMENTS:
		details.add_child(host.make_label(("✓ " if host.progress.rewards.achievements.has(id) else "○ ") + L10N.text(str(REWARDS.ACHIEVEMENTS[id])), 20))
	details.add_child(host.make_label(L10N.text("PERSONAL RECORDS (completed missions)"), 24, Color("84d8ff")))
	for key in host.progress.rewards.records:
		var record: Dictionary = host.progress.rewards.records[key]
		details.add_child(host.make_label(L10N.text("World %s: best accuracy %s • most correct %d") % [key, "%.0f%%" % (100 * float(record.accuracy)) if record.has("accuracy") else L10N.text("needs 10 answers"), int(record.hits)], 20))

	# A fixed footer keeps one short explanation visible while the inventory scrolls.
	var tip_panel := PanelContainer.new()
	tip_panel.add_theme_stylebox_override("panel", host.space_panel(Color("0b1935"), Color("8d6ade"), 16, 0.15))
	root.add_child(tip_panel)
	var tips := [
		"Complete missions: +40. New day: +30.",
		"Difficult facts: +25. Accuracy progress: +30.",
		"Hull designs change your look, not your battle strength.",
		"Energy reserve adds 15 hint energy at mission start.",
		"Repair pulse restores 15 shield once per mission.",
		"Upgrades help your ship. Knowledge grows only through your answers."
	]
	var row := HBoxContainer.new()
	tip_panel.add_child(row)
	var caption: Label = host.make_label("", 19, Color("d5e4ff"))
	caption.name = "HangarTip"
	caption.custom_minimum_size.y = 58
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var update_tip := func(direction: int):
		var index: int = posmod(int(host.get_meta("hangar_tip", 0)) + direction, tips.size())
		host.set_meta("hangar_tip", index)
		caption.text = "%d / %d   •   %s" % [index + 1, tips.size(), L10N.text(tips[index])]
	row.add_child(host.make_button("‹", func(): update_tip.call(-1), Color("6651b4"), 54, 54, 28))
	row.add_child(caption)
	row.add_child(host.make_button("›", func(): update_tip.call(1), Color("6651b4"), 54, 54, 28))
	update_tip.call(0)
