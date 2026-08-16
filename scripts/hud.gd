class_name HUD
extends CanvasLayer


const HIT_FEEDBACK_SCRIPT := preload("res://scripts/hit_feedback.gd")

var player: Player
var bot: DuelBot
var health_value: Label
var ammo_value: Label
var score_value: Label
var time_value: Label
var message_label: Label
var crosshair: Crosshair
var reload_bar: ProgressBar
var death_overlay: ColorRect
var scope_overlay: ScopeOverlay
var interact_prompt: Label
var loadout_panel: PanelContainer
var stats_panel: PanelContainer
var stats_title: Label
var stats_body: Label
var weapon_buttons: Dictionary = {}
var _loadout_buttons: Dictionary = {}
var zombie_mode := false
var quickscope_mode := false
var parkour_mode := false
var current_player_score := 0
var current_bot_score := 0
var hit_feedback: Control
var weapon_bar: Control


func _ready() -> void:
	layer = 10
	_build_ui()


func _process(_delta: float) -> void:
	if player == null or player.weapon == null:
		return
	if reload_bar != null:
		reload_bar.value = player.weapon.get_reload_progress()
	var scoped := player.weapon.current_weapon_id == "operator" and player.weapon.ads_amount > 0.5
	scope_overlay.visible = scoped
	crosshair.visible = not scoped
	interact_prompt.visible = false
	for rope in get_tree().get_nodes_in_group("rope_teleporter"):
		if rope.active:
			interact_prompt.visible = true
			break


func setup(target_player: Player, target_bot: DuelBot) -> void:
	player = target_player
	bot = target_bot
	var settings := get_node_or_null("/root/Settings")
	quickscope_mode = settings != null and settings.game_mode == "quickscope"
	parkour_mode = settings != null and settings.game_mode == "parkour"
	if (quickscope_mode or parkour_mode) and weapon_bar != null:
		weapon_bar.visible = false
	if quickscope_mode and time_value != null:
		time_value.visible = true
	crosshair.player = player
	player.health_changed.connect(_on_health_changed)
	player.weapon.ammo_changed.connect(_on_ammo_changed)
	player.weapon.reload_started.connect(_on_reload_started)
	player.weapon.reload_finished.connect(_on_ammo_changed)
	player.weapon.weapon_selected.connect(_on_weapon_selected)
	player.hit_marker.connect(crosshair.trigger_hitmarker)
	player.damaged.connect(hit_feedback.trigger)
	player.shield_changed.connect(_on_shield_changed)
	player.died.connect(_on_player_died_ui)
	player.respawned.connect(_on_player_respawned_ui)
	_on_health_changed(player.health, player.max_health)
	_on_shield_changed(player.shield_active)
	_on_ammo_changed(player.weapon.magazine, player.weapon.reserve)
	_on_weapon_selected(player.weapon.current_weapon_id)
	update_score(0, 0)


func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	crosshair = Crosshair.new()
	crosshair.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(crosshair)

	death_overlay = ColorRect.new()
	death_overlay.color = Color(0.45, 0.04, 0.04, 0.30)
	death_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	death_overlay.visible = false
	root.add_child(death_overlay)

	hit_feedback = HIT_FEEDBACK_SCRIPT.new()
	hit_feedback.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(hit_feedback)

	scope_overlay = ScopeOverlay.new()
	scope_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	scope_overlay.visible = false
	root.add_child(scope_overlay)

	var top_left := VBoxContainer.new()
	top_left.position = Vector2(24.0, 20.0)
	top_left.add_theme_constant_override("separation", 8)
	root.add_child(top_left)

	health_value = _make_label(26, Color(1.0, 1.0, 1.0))
	ammo_value = _make_label(26, Color(1.0, 0.88, 0.55))
	score_value = _make_label(24, Color(0.75, 0.9, 1.0))
	time_value = _make_label(24, Color(0.95, 0.75, 0.45))
	time_value.visible = false
	reload_bar = ProgressBar.new()
	reload_bar.custom_minimum_size = Vector2(190.0, 8.0)
	reload_bar.max_value = 1.0
	reload_bar.show_percentage = false
	reload_bar.visible = false
	top_left.add_child(health_value)
	top_left.add_child(ammo_value)
	top_left.add_child(score_value)
	top_left.add_child(time_value)
	top_left.add_child(reload_bar)

	message_label = _make_label(72, Color(1.0, 0.95, 0.85))
	message_label.visible = false
	message_label.set_anchors_preset(Control.PRESET_CENTER)
	message_label.position = Vector2(-220.0, -40.0)
	message_label.custom_minimum_size = Vector2(440.0, 120.0)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	root.add_child(message_label)

	stats_panel = PanelContainer.new()
	stats_panel.visible = false
	stats_panel.set_anchors_preset(Control.PRESET_CENTER)
	stats_panel.position = Vector2(-270.0, -220.0)
	stats_panel.custom_minimum_size = Vector2(540.0, 440.0)
	stats_panel.add_theme_stylebox_override("panel", _hud_panel_style())
	root.add_child(stats_panel)
	var stats_vbox := VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 10)
	stats_panel.add_child(stats_vbox)
	stats_title = _make_label(34, Color(1.0, 0.9, 0.8))
	stats_title.text = "对局结束"
	stats_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_vbox.add_child(stats_title)
	stats_body = _make_label(22, Color(0.9, 0.94, 1.0))
	stats_body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stats_vbox.add_child(stats_body)
	var stats_buttons := HBoxContainer.new()
	stats_buttons.add_theme_constant_override("separation", 8)
	stats_vbox.add_child(stats_buttons)
	var back_button := Button.new()
	back_button.text = "回到主界面"
	back_button.custom_minimum_size = Vector2(0.0, 44.0)
	back_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back_button.pressed.connect(_on_back_to_menu_pressed)
	stats_buttons.add_child(back_button)
	var again_button := Button.new()
	again_button.text = "再来一局"
	again_button.custom_minimum_size = Vector2(0.0, 44.0)
	again_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	again_button.pressed.connect(_on_play_again_pressed)
	stats_buttons.add_child(again_button)
	var quit_button := Button.new()
	quit_button.text = "退出至桌面"
	quit_button.custom_minimum_size = Vector2(0.0, 44.0)
	quit_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quit_button.pressed.connect(_on_quit_to_desktop_pressed)
	stats_buttons.add_child(quit_button)

	interact_prompt = _make_label(26, Color(1.0, 0.9, 0.7))
	interact_prompt.text = "E  绳索传送"
	interact_prompt.visible = false
	interact_prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	interact_prompt.position = Vector2(-120.0, -230.0)
	interact_prompt.custom_minimum_size = Vector2(240.0, 40.0)
	interact_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(interact_prompt)

	var bottom_center := CenterContainer.new()
	bottom_center.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	bottom_center.position = Vector2(-320.0, -118.0)
	bottom_center.custom_minimum_size = Vector2(640.0, 64.0)
	root.add_child(bottom_center)
	weapon_bar = bottom_center
	var bar_panel := PanelContainer.new()
	bar_panel.add_theme_stylebox_override("panel", _hud_panel_style())
	bottom_center.add_child(bar_panel)
	var weapon_hbox := HBoxContainer.new()
	weapon_hbox.add_theme_constant_override("separation", 6)
	bar_panel.add_child(weapon_hbox)
	for i in Weapon.WEAPON_ORDER.size():
		var weapon_id: String = Weapon.WEAPON_ORDER[i]
		var button := Button.new()
		button.text = "%d %s" % [i + 1, Weapon.WEAPON_DEFS[weapon_id]["name"]]
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_on_weapon_button_pressed.bind(weapon_id))
		weapon_buttons[weapon_id] = button
		weapon_hbox.add_child(button)

	loadout_panel = PanelContainer.new()
	loadout_panel.visible = false
	loadout_panel.set_anchors_preset(Control.PRESET_CENTER)
	loadout_panel.position = Vector2(-230.0, -270.0)
	loadout_panel.custom_minimum_size = Vector2(460.0, 500.0)
	loadout_panel.add_theme_stylebox_override("panel", _hud_panel_style())
	root.add_child(loadout_panel)
	var loadout_vbox := VBoxContainer.new()
	loadout_vbox.add_theme_constant_override("separation", 10)
	loadout_panel.add_child(loadout_vbox)
	var loadout_title := _make_label(28, Color(1.0, 0.9, 0.8))
	loadout_title.text = "选择枪械"
	loadout_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loadout_vbox.add_child(loadout_title)
	for i in Weapon.WEAPON_ORDER.size():
		var weapon_id: String = Weapon.WEAPON_ORDER[i]
		var button := Button.new()
		button.text = "%d. %s" % [i + 1, Weapon.WEAPON_DEFS[weapon_id]["name"]]
		button.custom_minimum_size = Vector2(0.0, 46.0)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_on_weapon_button_pressed.bind(weapon_id))
		_loadout_buttons[weapon_id] = button
		loadout_vbox.add_child(button)


func _make_label(size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.75))
	label.add_theme_constant_override("outline_size", 8)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func update_score(player_score: int, bot_score: int) -> void:
	current_player_score = player_score
	current_bot_score = bot_score
	if score_value != null:
		if zombie_mode:
			score_value.text = "KILLS %d" % player_score
		elif parkour_mode:
			score_value.text = "PARKOUR"
		else:
			score_value.text = "YOU %d   -   %d BOT" % [player_score, bot_score]


func update_time(seconds_left: float) -> void:
	if time_value == null:
		return
	var seconds := maxi(0, int(ceil(seconds_left)))
	time_value.text = "TIME %02d" % seconds
	time_value.add_theme_color_override("font_color", Color(0.95, 0.3, 0.2) if seconds <= 10 else Color(0.95, 0.75, 0.45))


func set_zombie_mode(enabled: bool) -> void:
	zombie_mode = enabled
	update_score(current_player_score, current_bot_score)


func show_message(text: String, _final: bool) -> void:
	message_label.text = text
	message_label.visible = true


func show_end_stats(stats: Dictionary, is_zombie: bool) -> void:
	stats_panel.visible = true
	var score_text := "%.1f" % float(stats["score"]) if is_zombie else str(int(stats["score"]))
	var hits: int = stats["hits"]
	var shots: int = stats["shots"]
	var headshots: int = stats["headshots"]
	var headshot_rate := 0.0 if hits == 0 else float(headshots) / float(hits) * 100.0
	var accuracy := 0.0 if shots == 0 else float(hits) / float(shots) * 100.0
	stats_body.text = "积分: %s\n伤害总量: %d\n爆头率: %.1f%%\n击杀: %d\n命中率: %.1f%%\n死亡: %d" % [
		score_text,
		int(stats["damage"]),
		headshot_rate,
		int(stats["kills"]),
		accuracy,
		int(stats["deaths"])
	]


func _on_back_to_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu.tscn")


func _on_play_again_pressed() -> void:
	get_tree().reload_current_scene()


func _on_quit_to_desktop_pressed() -> void:
	get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if quickscope_mode or parkour_mode:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_B:
		loadout_panel.visible = not loadout_panel.visible
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if loadout_panel.visible else Input.MOUSE_MODE_CAPTURED


func _on_health_changed(current: int, maximum: int) -> void:
	_update_health_label()


func _on_shield_changed(active: bool) -> void:
	_update_health_label()


func _update_health_label() -> void:
	if health_value == null or player == null:
		return
	var suffix := ""
	var label_color := Color(1.0, 1.0, 1.0)
	if player.shield_active:
		suffix += "  [SHIELD]"
		label_color = Color(0.55, 0.85, 1.0)
	elif player.health <= 40:
		label_color = Color(0.95, 0.25, 0.2)
	var settings := get_node_or_null("/root/Settings")
	if settings != null and settings.player_invincible:
		suffix += "  [INVINCIBLE]"
		label_color = Color(1.0, 0.85, 0.35)
	health_value.text = "HP %d / %d%s" % [player.health, player.max_health, suffix]
	health_value.add_theme_color_override("font_color", label_color)


func _on_ammo_changed(magazine: int, reserve: int) -> void:
	if ammo_value == null:
		return
	if player != null and player.weapon.current_def["type"] == "melee":
		ammo_value.text = "MELEE"
	else:
		var settings := get_node_or_null("/root/Settings")
		var infinite_mag: bool = quickscope_mode or (settings != null and bool(settings.infinite_magazine))
		var infinite_ammo: bool = settings != null and bool(settings.infinite_ammo)
		if infinite_mag and infinite_ammo:
			ammo_value.text = "∞ / ∞"
		elif infinite_mag:
			ammo_value.text = "∞ / %d" % reserve
		elif infinite_ammo:
			ammo_value.text = "%d / ∞" % magazine
		else:
			ammo_value.text = "%d / %d" % [magazine, reserve]
	if reload_bar != null:
		reload_bar.visible = false


func _on_reload_started() -> void:
	ammo_value.text = "RELOADING"
	if reload_bar != null:
		reload_bar.visible = true


func _on_weapon_selected(weapon_id: String) -> void:
	for id in weapon_buttons:
		var button: Button = weapon_buttons[id]
		button.modulate = Color(1.0, 1.0, 1.0) if id == weapon_id else Color(0.55, 0.55, 0.58)
	for id in _loadout_buttons:
		var button: Button = _loadout_buttons[id]
		button.modulate = Color(1.0, 1.0, 1.0) if id == weapon_id else Color(0.6, 0.6, 0.64)
	_on_ammo_changed(player.weapon.magazine, player.weapon.reserve)


func _on_weapon_button_pressed(weapon_id: String) -> void:
	if player != null and player.weapon != null:
		player.weapon.select_weapon_id(weapon_id)
		loadout_panel.visible = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_player_died_ui() -> void:
	death_overlay.visible = true


func _on_player_respawned_ui() -> void:
	death_overlay.visible = false


func _hud_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.07, 0.11, 0.82)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.set_border_width_all(1)
	style.border_color = Color(1.0, 1.0, 1.0, 0.12)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style
