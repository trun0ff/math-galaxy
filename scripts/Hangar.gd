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
	content.add_child(host.make_label(L10N.text("FLEET • armor and reactor capacity"), 26, Color("84d8ff")))
	var hulls := GridContainer.new()
	hulls.columns = 3
	hulls.add_theme_constant_override("h_separation", 14)
	hulls.add_theme_constant_override("v_separation", 14)
	content.add_child(hulls)
	for id in REWARDS.FLEET.SHIP_IDS:
		add_item(host, hulls, str(id), "ship")
	content.add_child(host.make_label(L10N.text("ARSENAL • match weapon power to your reactor"), 26, Color("84d8ff")))
	var weapons := GridContainer.new()
	weapons.columns = 3
	weapons.add_theme_constant_override("h_separation", 14)
	weapons.add_theme_constant_override("v_separation", 14)
	content.add_child(weapons)
	for id in REWARDS.FLEET.WEAPON_IDS:
		add_item(host, weapons, str(id), "weapon")
	var upgrades := GridContainer.new()
	upgrades.columns = 2
	content.add_child(upgrades)
	for id in ["battery", "repair"]:
		add_item(host, upgrades, id, "upgrade")
	var resize_cards := func():
		var columns := clampi(int(scroll.size.x / 310.0), 1, 3)
		hulls.columns = columns
		weapons.columns = columns
		upgrades.columns = mini(columns, 2)
	scroll.resized.connect(resize_cards)
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
		"One monster per mission. At least 10 correct hits to win.",
		"Difficult facts: +25. Accuracy progress: +30.",
		"Armor reduces damage. Reactors support stronger weapons.",
		"Energy reserve adds 15 hint energy at mission start.",
		"Repair pulse restores 15 shield once per mission.",
		"Focus support keeps older gear viable. Strong gear reaches the mission hit minimum."
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

static func add_item(host: Control, grid: GridContainer, id: String, kind: String) -> void:
	var fleet = REWARDS.FLEET
	var index: int = fleet.ship_index(id) if kind == "ship" else fleet.weapon_index(id)
	var accent := Color(fleet.SHIP_TINTS[index]) if kind == "ship" else Color(fleet.COLORS[index]) if kind == "weapon" else Color("84d8ff")
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", host.space_panel(Color("091831"), accent, 16, 0.18))
	grid.add_child(panel)
	var card := VBoxContainer.new()
	card.add_theme_constant_override("separation", 8)
	panel.add_child(card)
	var title: String = fleet.SHIP_NAMES[index] if kind == "ship" else fleet.WEAPON_NAMES[index] if kind == "weapon" else REWARDS.CATALOG[id].name
	card.add_child(host.make_label(L10N.text(title), 22, accent))
	if kind != "upgrade":
		var preview := TextureRect.new()
		preview.name = ("HullPreview_" if kind == "ship" else "WeaponPreview_") + id
		preview.texture = fleet.ship_texture(id) if kind == "ship" else load("res://assets/battle/%s.png" % id) if id.begins_with("weapon_") else null
		if kind == "ship":
			preview.set_script(preload("res://scripts/ui/EnginePreview.gd"))
			var material := ShaderMaterial.new()
			material.shader = preload("res://assets/shaders/ship_engine.gdshader")
			material.set_shader_parameter("engine_color", accent)
			preview.material = material
		preview.custom_minimum_size = Vector2(240, 120 if kind == "weapon" else 155)
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		card.add_child(preview)
		if preview.texture == null:
			preview.custom_minimum_size.y = 0
			card.add_child(host.make_label("✦  " + L10N.text(title), 20, Color(fleet.COLORS[index])))
	var description: String
	if kind == "ship":
		description = L10N.text("Armor %d • Reactor %d • Damage +%d%%") % [fleet.ARMOR[index], fleet.POWER[index], fleet.BONUS[index]]
	elif kind == "weapon":
		description = L10N.text("Damage %d • Requires reactor %d") % [fleet.DAMAGE[index], fleet.DRAW[index]]
	else:
		description = L10N.text(REWARDS.CATALOG[id].description)
	var label: Label = host.make_label(description, 17, Color("b3cbe7"))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(label)
	var owned: bool = id in ["default", "laser"] or host.progress.rewards.owned.has(id)
	var equipped: bool = (host.progress.rewards.equipped == id if kind == "ship" else host.progress.rewards.weapon == id if kind == "weapon" else owned)
	var compatible: bool = kind != "weapon" or fleet.DRAW[index] <= fleet.POWER[fleet.ship_index(host.progress.rewards.equipped)]
	var caption: String = L10N.text("EQUIPPED") if equipped else L10N.text("OWNED") if owned and kind == "upgrade" else L10N.text("EQUIP") if owned else L10N.text("%d CRYSTALS") % int(REWARDS.CATALOG[id].cost)
	if not compatible: caption = L10N.text("Requires reactor %d") % fleet.DRAW[index]
	var button: Button = host.make_button(caption, func():
		if owned: host.equip_hangar(id)
		else: host.buy_hangar(id)
	, accent, 240, 46, 17)
	button.disabled = equipped or not compatible
	card.add_child(button)
