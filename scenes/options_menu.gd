extends Control

const LANGUAGE_MANAGER_PATH := "/root/Localization"

func _ready():
	var language_manager = get_node_or_null(LANGUAGE_MANAGER_PATH)
	var languages: Array[Dictionary] = []
	if language_manager != null:
		languages = language_manager.get_languages()
	if language_manager == null or languages.size() <= 1:
		$Panel/VBoxContainer/LanguageLabel.hide()
		%LanguageOption.hide()
	else:
		var selected_index := 0
		for language in languages:
			var item_index: int = %LanguageOption.item_count
			%LanguageOption.add_item(language["name"])
			%LanguageOption.set_item_metadata(item_index, language["locale"])
			if language["locale"] == language_manager.get_locale():
				selected_index = item_index
		%LanguageOption.select(selected_index)

	var sfx_index = AudioServer.get_bus_index("Music")
	var start_value = AudioServer.get_bus_volume_db(sfx_index)
	%MusicSlider.value = db_to_linear(start_value)

	var sfx_index2 = AudioServer.get_bus_index("sfx")
	var start_value2 = AudioServer.get_bus_volume_db(sfx_index2)
	%SFXSlider.value = db_to_linear(start_value2)

	if get_window().mode == Window.MODE_FULLSCREEN:
		%FullscreenSwitch.button_pressed = true
	else:
		%FullscreenSwitch.button_pressed = false

func _on_button_pressed():
	save_config()

	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func save_config():
	var config = GlobalVariables.config
	config.set_value("Audio", "music", %MusicSlider.value)
	config.set_value("Audio", "sfx", %SFXSlider.value)
	config.set_value("Video", "fullscreen", %FullscreenSwitch.button_pressed)
	config.set_value("Language", "locale", TranslationServer.get_locale())
	config.save("user://options.cfg")

func _on_slider_value_changed(value: float, bus: StringName) -> void:
	var bus_index = AudioServer.get_bus_index(bus)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))


func _on_fullscreen_toggled(toggled_on: bool) -> void:
	GlobalVariables.update_fullscreen(toggled_on)

func _on_language_selected(index: int) -> void:
	var language_manager = get_node_or_null(LANGUAGE_MANAGER_PATH)
	if language_manager == null:
		return
	var locale = %LanguageOption.get_item_metadata(index)
	language_manager.set_locale(locale)
