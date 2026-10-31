extends RefCounted

const L10N = preload("res://scripts/Localization.gd")

const REWARDS = preload("res://scripts/RewardManager.gd")

static func show(host: Control, notice: String = "") -> void:
	REWARDS.migrate(host.progress)
	host.screen = "hangar"
	var root: VBoxContainer = host.build_root(host.MENU_GALAXY)
	root.add_child(host.make_button(L10N.text("◀ GALAXY"), host.show_menu, Color("425d88"), 180, 48, 20))
	root.add_child(host.make_label(L10N.text("HANGAR  •  %d CRYSTALS") % int(host.progress.coins), 34, Color("84d8ff")))
	root.add_child(host.make_label(L10N.text("Complete missions: +40. New day: +30. Difficult facts: +25. Accuracy progress: +30."), 18))
	root.add_child(host.make_label(L10N.text("Upgrades help your ship. Knowledge grows only through your answers."), 18))
	if not notice.is_empty(): root.add_child(host.make_label(notice, 20, Color("ffd85b")))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	scroll.add_child(content)
	content.add_child(host.make_button(L10N.text("EQUIP ORIGINAL HULL"), func(): host.equip_hangar("default"), Color("2865ad"), 250, 44, 18))
	for id in REWARDS.CATALOG:
		var item: Dictionary = REWARDS.CATALOG[id]
		var row := HBoxContainer.new()
		content.add_child(row)
		var owned: bool = host.progress.rewards.owned.has(id)
		var caption := "%s — %s" % [L10N.text(item.name), L10N.text(item.description)]
		var label: Label = host.make_label(caption, 20)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var cosmetic: bool = id in ["violet", "gold"]
		var text := L10N.text("EQUIPPED") if host.progress.rewards.equipped == id else L10N.text("EQUIP") if owned and cosmetic else L10N.text("OWNED") if owned else L10N.text("%d CRYSTALS") % int(item.cost)
		var button: Button = host.make_button(text, func(): host.buy_hangar(id), Color("2865ad"), 200, 52, 18)
		button.disabled = (owned and not cosmetic) or host.progress.rewards.equipped == id or (not owned and int(host.progress.coins) < int(item.cost))
		row.add_child(button)
	content.add_child(host.make_label(L10N.text("ACHIEVEMENTS  (+25 each, once)"), 24, Color("ffd85b")))
	for id in REWARDS.ACHIEVEMENTS:
		content.add_child(host.make_label(("✓ " if host.progress.rewards.achievements.has(id) else "○ ") + L10N.text(str(REWARDS.ACHIEVEMENTS[id])), 20))
	content.add_child(host.make_label(L10N.text("PERSONAL RECORDS (completed missions)"), 24, Color("84d8ff")))
	for key in host.progress.rewards.records:
		var record: Dictionary = host.progress.rewards.records[key]
		content.add_child(host.make_label(L10N.text("World %s: best accuracy %s • most correct %d") % [key, "%.0f%%" % (100 * float(record.accuracy)) if record.has("accuracy") else L10N.text("needs 10 answers"), int(record.hits)], 20))
