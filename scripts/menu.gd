class_name MainMenu
extends Control


var _fullscreen_check: CheckButton
var _sensitivity_slider: HSlider
var _sensitivity_value: Label
var _map_buttons: Dictionary = {}
var _difficulty_buttons: Dictionary = {}
var _infinite_ammo_check: CheckButton
var _infinite_magazine_check: CheckButton


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

	var start_button := _make_button("经典对决", Color(0.82, 0.22, 0.18), Color(0.95, 0.30, 0.24))
	start_button.custom_minimum_size = Vector2(0.0, 54.0)
	start_button.tooltip_text = "1v1 对战机器人，先到 10 杀获胜。"
	start_button.pressed.connect(_on_start_pressed)
	vbox.add_child(start_button)

	var zombie_button := _make_button("生化模式", Color(0.18, 0.55, 0.32), Color(0.24, 0.72, 0.42))
	zombie_button.custom_minimum_size = Vector2(0.0, 54.0)
	zombie_button.tooltip_text = "1000 血量，死一次即失败；僵尸每 5 秒生成，只能拿刀近战。"
	zombie_button.pressed.connect(_on_zombie_pressed)
	vbox.add_child(zombie_button)

	vbox.add_child(HSeparator.new())

	var map_title := Label.new()
	map_title.text = "地图"
	map_title.add_theme_font_size_override("font_size", 18)
	map_title.add_theme_color_override("font_color", Color(0.78, 0.82, 0.9))
	vbox.add_child(map_title)

	var map_row := HBoxContainer.new()
	map_row.add_theme_constant_override("separation", 8)
	vbox.add_child(map_row)
	var tower_button := _make_button("三层塔楼", Color(0.35, 0.62, 0.88), Color(0.45, 0.72, 0.95))
	tower_button.custom_minimum_size = Vector2(0.0, 48.0)
	tower_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tower_button.tooltip_text = "三层立体地图，包含垂直/水平绳索、弹跳板和虫洞传送。"
	tower_button.pressed.connect(_on_map_pressed.bind("tower"))
	_map_buttons["tower"] = tower_button
	map_row.add_child(tower_button)
	var field_button := _make_button("野战掩体", Color(0.45, 0.62, 0.30), Color(0.55, 0.72, 0.38))
	field_button.custom_minimum_size = Vector2(0.0, 48.0)
	field_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field_button.tooltip_text = "开阔野战图，有长草丛、可破坏木箱和中央拱桥。"
	field_button.pressed.connect(_on_map_pressed.bind("field"))
	_map_buttons["field"] = field_button
	map_row.add_child(field_button)

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

	var infinite_ammo_row := HBoxContainer.new()
	var infinite_ammo_label := Label.new()
	infinite_ammo_label.text = "无限子弹"
	infinite_ammo_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_infinite_ammo_check = CheckButton.new()
	_infinite_ammo_check.toggled.connect(_on_infinite_ammo_toggled)
	infinite_ammo_row.add_child(infinite_ammo_label)
	infinite_ammo_row.add_child(_infinite_ammo_check)
	vbox.add_child(infinite_ammo_row)

	var infinite_mag_row := HBoxContainer.new()
	var infinite_mag_label := Label.new()
	infinite_mag_label.text = "无限弹夹"
	infinite_mag_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_infinite_magazine_check = CheckButton.new()
	_infinite_magazine_check.toggled.connect(_on_infinite_magazine_toggled)
	infinite_mag_row.add_child(infinite_mag_label)
	infinite_mag_row.add_child(_infinite_magazine_check)
	vbox.add_child(infinite_mag_row)

	var difficulty_title := Label.new()
	difficulty_title.text = "生化难度"
	difficulty_title.add_theme_font_size_override("font_size", 18)
	difficulty_title.add_theme_color_override("font_color", Color(0.78, 0.82, 0.9))
	vbox.add_child(difficulty_title)
	var difficulty_row := HBoxContainer.new()
	difficulty_row.add_theme_constant_override("separation", 6)
	vbox.add_child(difficulty_row)
	var difficulties := {
		"easy": "简单",
		"normal": "中等",
		"hard": "困难",
		"insane": "吊炸天"
	}
	for difficulty_id in difficulties:
		var difficulty_button := _make_button(difficulties[difficulty_id], Color(0.28, 0.38, 0.48), Color(0.38, 0.50, 0.62))
		difficulty_button.custom_minimum_size = Vector2(0.0, 40.0)
		difficulty_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		difficulty_button.pressed.connect(_on_difficulty_pressed.bind(difficulty_id))
		_difficulty_buttons[difficulty_id] = difficulty_button
		difficulty_row.add_child(difficulty_button)

	var controls_label := _make_label(15, Color(0.75, 0.82, 0.9))
	controls_label.text = "WASD 移动  鼠标 视角  左键 射击  右键 开镜  R 换弹  Shift 慢走  Ctrl 蹲  Space 跳  F 检视  B 选枪  E 绳索  Esc 退出"
	controls_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(controls_label)

	vbox.add_child(HSeparator.new())

	var quit_button := _make_button("退出游戏", Color(0.12, 0.14, 0.18), Color(0.20, 0.24, 0.30))
	quit_button.custom_minimum_size = Vector2(0.0, 46.0)
	quit_button.pressed.connect(_on_quit_pressed)
	vbox.add_child(quit_button)


func _sync_controls() -> void:
	var settings := _settings_node()
	var fullscreen := false
	var sensitivity := 0.0018
	var selected_map := "tower"
	var infinite_ammo := false
	var infinite_magazine := false
	var difficulty := "normal"
	if settings != null:
		fullscreen = settings.fullscreen
		sensitivity = settings.mouse_sensitivity
		selected_map = settings.selected_map
		infinite_ammo = settings.infinite_ammo
		infinite_magazine = settings.infinite_magazine
		difficulty = settings.zombie_difficulty
	_fullscreen_check.button_pressed = fullscreen
	_infinite_ammo_check.button_pressed = infinite_ammo
	_infinite_magazine_check.button_pressed = infinite_magazine
	var multiplier := sensitivity / 0.0018
	_sensitivity_slider.set_value_no_signal(multiplier)
	_sensitivity_value.text = "%.2fx" % multiplier
	for map_id in _map_buttons:
		var button: Button = _map_buttons[map_id]
		button.modulate = Color(1.0, 1.0, 1.0) if map_id == selected_map else Color(0.55, 0.55, 0.58)
	for difficulty_id in _difficulty_buttons:
		var button: Button = _difficulty_buttons[difficulty_id]
		button.modulate = Color(1.0, 1.0, 1.0) if difficulty_id == difficulty else Color(0.55, 0.55, 0.58)


func _on_start_pressed() -> void:
	var settings := _settings_node()
	if settings != null:
		settings.game_mode = "classic"
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_zombie_pressed() -> void:
	var settings := _settings_node()
	if settings != null:
		settings.game_mode = "zombie"
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


func _on_map_pressed(map_id: String) -> void:
	var settings := _settings_node()
	if settings != null:
		settings.selected_map = map_id
	for id in _map_buttons:
		var button: Button = _map_buttons[id]
		button.modulate = Color(1.0, 1.0, 1.0) if id == map_id else Color(0.55, 0.55, 0.58)


func _on_infinite_ammo_toggled(enabled: bool) -> void:
	var settings := _settings_node()
	if settings != null:
		settings.infinite_ammo = enabled
		settings.save_settings()


func _on_infinite_magazine_toggled(enabled: bool) -> void:
	var settings := _settings_node()
	if settings != null:
		settings.infinite_magazine = enabled
		settings.save_settings()


func _on_difficulty_pressed(difficulty_id: String) -> void:
	var settings := _settings_node()
	if settings != null:
		settings.zombie_difficulty = difficulty_id
	for id in _difficulty_buttons:
		var button: Button = _difficulty_buttons[id]
		button.modulate = Color(1.0, 1.0, 1.0) if id == difficulty_id else Color(0.55, 0.55, 0.58)


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


func _make_label(size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.75))
	label.add_theme_constant_override("outline_size", 6)
	return label
