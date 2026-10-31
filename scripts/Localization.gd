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

static var location_words := RegEx.create_from_string("(?i)\\b(sublevels?|levels?)\\b")

static func text(source: String) -> String:
	var value: String = str(catalog.get(source, source)) if language == "uk" else source
	# Keep legacy translation keys/save identifiers stable; rename visible English terms.
	var matches := location_words.search_all(value)
	matches.reverse()
	for found in matches:
		var word: String = found.get_string()
		var replacement := "locations" if word.to_lower().ends_with("s") else "location"
		if word == word.to_upper(): replacement = replacement.to_upper()
		elif word[0] == word[0].to_upper(): replacement = replacement.capitalize()
		value = value.substr(0, found.get_start()) + replacement + value.substr(found.get_end())
	return value
