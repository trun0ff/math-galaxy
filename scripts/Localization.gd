extends RefCounted

const SETTINGS_PATH := "user://language.cfg"
const CATALOG = preload("res://scripts/TranslationCatalog.gd")
static var language: String = "en"
static var catalog: Dictionary = CATALOG.UK

static func initialize() -> void:
	var settings := ConfigFile.new()
	var selected := "en"
	if settings.load(SETTINGS_PATH) == OK:
		selected = str(settings.get_value("interface", "language", "en"))
	apply_language(selected)

static func apply_language(value: String) -> void:
	language = value if value in ["en", "uk"] else "en"
	TranslationServer.set_locale(language)

static func select_language(value: String) -> Error:
	apply_language(value)
	var settings := ConfigFile.new()
	settings.set_value("interface", "language", language)
	return settings.save(SETTINGS_PATH)

static func text(source: String) -> String:
	return str(catalog.get(source, source)) if language == "uk" else source
