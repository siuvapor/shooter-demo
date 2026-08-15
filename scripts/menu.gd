class_name MainMenu
extends Control


var _fullscreen_check: CheckButton
var _sensitivity_slider: HSlider
var _sensitivity_value: Label


func _ready() -> void:
	_build_ui()
	_sync_controls()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().quit()


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var background := TextureRect.new()
	background.texture = load("res://outputs/screenshot.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var overlay := ColorRect.new()
	overlay.color = Color(0.03, 0.04, 0.07, 0.72)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style())
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(430.0, 0.0)
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "SHOOTER DEMO"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 46)
	title.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	title.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.85))
	title.add_theme_constant_override("outline_size", 10)
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "VALORANT STYLE 1V1 DUEL"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", Color(1.0, 0.42, 0.32))
	vbox.add_child(subtitle)
	vbox.add_child(HSeparator.new())

	var start_button := _make_button("开始游戏", Color(0.82, 0.22, 0.18), Color(0.95, 0.30, 0.24))
	start_button.custom_minimum_size = Vector2(0.0, 54.0)
	start_button.pressed.connect(_on_start_pressed)
	vbox.add_child(start_button)

	vbox.add_child(HSeparator.new())

	var settings_title := Label.new()
	settings_title.text = "设置"
	settings_title.add_theme_font_size_override("font_size", 18)
	settings_title.add_theme_color_override("font_color", Color(0.78, 0.82, 0.9))
	vbox.add_child(settings_title)

	var fullscreen_row := HBoxContainer.new()
	var fullscreen_label := Label.new()
	fullscreen_label.text = "全屏"
	fullscreen_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fullscreen_check = CheckButton.new()
	_fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	fullscreen_row.add_child(fullscreen_label)
	fullscreen_row.add_child(_fullscreen_check)
	vbox.add_child(fullscreen_row)

	var sensitivity_row := HBoxContainer.new()
	var sensitivity_label := Label.new()
	sensitivity_label.text = "灵敏度"
	sensitivity_label.custom_minimum_size = Vector2(90.0, 0.0)
	_sensitivity_slider = HSlider.new()
	_sensitivity_slider.min_value = 0.5
	_sensitivity_slider.max_value = 3.0
	_sensitivity_slider.step = 0.05
	_sensitivity_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	_sensitivity_value = Label.new()
	_sensitivity_value.custom_minimum_size = Vector2(72.0, 0.0)
	_sensitivity_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	sensitivity_row.add_child(sensitivity_label)
	sensitivity_row.add_child(_sensitivity_slider)
	sensitivity_row.add_child(_sensitivity_value)
	vbox.add_child(sensitivity_row)

	vbox.add_child(HSeparator.new())

	var quit_button := _make_button("退出游戏", Color(0.12, 0.14, 0.18), Color(0.20, 0.24, 0.30))
	quit_button.custom_minimum_size = Vector2(0.0, 46.0)
	quit_button.pressed.connect(_on_quit_pressed)
	vbox.add_child(quit_button)


func _sync_controls() -> void:
	var settings := _settings_node()
	var fullscreen := false
	var sensitivity := 0.0018
	if settings != null:
		fullscreen = settings.fullscreen
		sensitivity = settings.mouse_sensitivity
	_fullscreen_check.button_pressed = fullscreen
	var multiplier := sensitivity / 0.0018
	_sensitivity_slider.set_value_no_signal(multiplier)
	_sensitivity_value.text = "%.2fx" % multiplier


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_fullscreen_toggled(enabled: bool) -> void:
	var settings := _settings_node()
	if settings != null:
		settings.set_fullscreen(enabled)


func _on_sensitivity_changed(value: float) -> void:
	var settings := _settings_node()
	if settings != null:
		settings.set_sensitivity(settings.DEFAULT_SENSITIVITY * value)
	_sensitivity_value.text = "%.2fx" % value


func _settings_node() -> Node:
	return get_node_or_null("/root/Settings")


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.07, 0.11, 0.88)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.set_border_width_all(1)
	style.border_color = Color(0.9, 0.26, 0.2, 0.7)
	style.content_margin_left = 38
	style.content_margin_right = 38
	style.content_margin_top = 28
	style.content_margin_bottom = 28
	return style


func _make_button(text: String, base_color: Color, hover_color: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	button.add_theme_stylebox_override("normal", _button_style(base_color))
	button.add_theme_stylebox_override("hover", _button_style(hover_color))
	button.add_theme_stylebox_override("pressed", _button_style(hover_color.darkened(0.2)))
	button.add_theme_stylebox_override("focus", _button_style(base_color))
	return button


func _button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.set_border_width_all(1)
	style.border_color = Color(1.0, 1.0, 1.0, 0.14)
	return style
