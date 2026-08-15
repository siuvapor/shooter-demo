extends Node


const SETTINGS_PATH := "user://settings.cfg"
const DEFAULT_SENSITIVITY := 0.0018

var mouse_sensitivity := DEFAULT_SENSITIVITY
var fullscreen := false
var game_mode := "classic"


func _ready() -> void:
	load_settings()
	apply_window_mode()


func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	fullscreen = config.get_value("video", "fullscreen", false)
	mouse_sensitivity = config.get_value("mouse", "sensitivity", DEFAULT_SENSITIVITY)


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("video", "fullscreen", fullscreen)
	config.set_value("mouse", "sensitivity", mouse_sensitivity)
	config.save(SETTINGS_PATH)


func apply_window_mode() -> void:
	var window := get_window()
	if window == null:
		return
	window.mode = Window.MODE_FULLSCREEN if fullscreen else Window.MODE_WINDOWED


func set_fullscreen(value: bool) -> void:
	fullscreen = value
	apply_window_mode()
	save_settings()


func set_sensitivity(value: float) -> void:
	mouse_sensitivity = clampf(value, 0.0004, 0.008)
	save_settings()
