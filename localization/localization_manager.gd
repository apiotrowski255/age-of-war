extends Node

const TRANSLATION_PATH := "res://localization/translations.csv"
const FONT_PATH := "res://localization/chinese_font.tres"

var current_locale := "en"
var _default_locale := "en"
var _translations: Dictionary = {}
var _language_names: Dictionary = {}
var _language_order: Array[String] = []
var _fallback_font: Font
var _original_label_fonts: Dictionary = {}

func _ready() -> void:
	_load_translations()
	_fallback_font = load(FONT_PATH)
	get_tree().scene_changed.connect(_on_scene_changed)

	var saved_locale := _default_locale
	var global_variables = get_node_or_null("/root/GlobalVariables")
	if global_variables != null:
		saved_locale = global_variables.config.get_value("Language", "locale", _default_locale)
	set_locale(saved_locale, false)

func is_available() -> bool:
	return not _translations.is_empty()

func get_languages() -> Array[Dictionary]:
	if _language_order.is_empty():
		_load_translations()
	var languages: Array[Dictionary] = []
	for locale in _language_order:
		languages.append({
			"locale": locale,
			"name": _language_names.get(locale, locale)
		})
	return languages

func get_locale() -> String:
	return current_locale

func set_locale(locale: String, save_config := true) -> void:
	if not _translations.has(locale):
		locale = _default_locale
	current_locale = locale
	TranslationServer.set_locale(current_locale)
	call_deferred("_update_scene_fonts")
	if save_config:
		_save_locale()

func _load_translations() -> void:
	var file := FileAccess.open(TRANSLATION_PATH, FileAccess.READ)
	if file == null:
		return

	var rows := _parse_csv(file.get_as_text())
	if rows.is_empty():
		return
	var header: Array = rows[0]
	for column_index in range(1, header.size()):
		var descriptor: String = header[column_index]
		var separator: int = descriptor.find("__")
		var locale_id: String = descriptor
		var language_name: String = descriptor
		if separator >= 0:
			locale_id = descriptor.substr(0, separator)
			language_name = descriptor.substr(separator + 2)
		if locale_id.is_empty() or _translations.has(locale_id):
			continue

		var translation := Translation.new()
		translation.locale = locale_id
		for row in rows.slice(1):
			if row.size() <= column_index or row[0].is_empty():
				continue
			var source_text: String = row[0].replace("\r\n", "\n")
			var translated_text: String = row[column_index]
			if translated_text.is_empty():
				translated_text = source_text
			translation.add_message(source_text, translated_text)
			if source_text.contains("\n"):
				translation.add_message(source_text.replace("\n", "\r\n"), translated_text)
		_translations[locale_id] = translation
		_language_names[locale_id] = language_name if not language_name.is_empty() else locale_id
		_language_order.append(locale_id)
		TranslationServer.add_translation(translation)

	if _translations.has("en"):
		_default_locale = "en"
	else:
		_default_locale = _language_order[0] if not _language_order.is_empty() else "en"
	current_locale = _default_locale

func _parse_csv(text: String) -> Array:
	var rows: Array = []
	var row: Array = []
	var field := ""
	var quoted := false
	var index := 0
	while index < text.length():
		var character := text.substr(index, 1)
		if quoted:
			if character == "\"":
				if index + 1 < text.length() and text.substr(index + 1, 1) == "\"":
					field += "\""
					index += 1
				else:
					quoted = false
			else:
				if character != "\r":
					field += character
		else:
			if character == "\"":
				quoted = true
			elif character == ",":
				row.append(field)
				field = ""
			elif character == "\n":
				row.append(field)
				rows.append(row)
				row = []
				field = ""
			elif character != "\r":
				field += character
		index += 1

	if not row.is_empty() or not field.is_empty():
		row.append(field)
		rows.append(row)
	return rows

func _on_scene_changed(_scene: Node) -> void:
	call_deferred("_update_scene_fonts")

func _update_scene_fonts() -> void:
	if current_locale != _default_locale and _fallback_font != null:
		_apply_fallback_font()
	else:
		_restore_original_fonts()

func _apply_fallback_font() -> void:
	var scene_root := get_tree().current_scene
	if scene_root == null:
		return
	for node in scene_root.find_children("*", "Label", true, false):
		var label := node as Label
		if label == null or label.label_settings == null:
			continue
		var settings: LabelSettings = label.label_settings
		if not _original_label_fonts.has(settings):
			_original_label_fonts[settings] = settings.font
		settings.font = _fallback_font

func _restore_original_fonts() -> void:
	for settings in _original_label_fonts:
		if is_instance_valid(settings):
			settings.font = _original_label_fonts[settings]

func _save_locale() -> void:
	var global_variables = get_node_or_null("/root/GlobalVariables")
	if global_variables == null:
		return
	global_variables.config.set_value("Language", "locale", current_locale)
	global_variables.config.save("user://options.cfg")
