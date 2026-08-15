class_name HUD
extends CanvasLayer


var player: Player
var bot: DuelBot
var health_value: Label
var ammo_value: Label
var score_value: Label
var message_label: Label
var crosshair: Crosshair
var reload_bar: ProgressBar


func _ready() -> void:
	layer = 10
	_build_ui()


func _process(_delta: float) -> void:
	if player == null or player.weapon == null or reload_bar == null:
		return
	reload_bar.value = player.weapon.get_reload_progress()


func setup(target_player: Player, target_bot: DuelBot) -> void:
	player = target_player
	bot = target_bot
	crosshair.player = player
	player.health_changed.connect(_on_health_changed)
	player.weapon.ammo_changed.connect(_on_ammo_changed)
	player.weapon.reload_started.connect(_on_reload_started)
	player.weapon.reload_finished.connect(_on_ammo_changed)
	player.hit_marker.connect(crosshair.trigger_hitmarker)
	_on_health_changed(player.health, player.MAX_HEALTH)
	_on_ammo_changed(player.weapon.magazine, player.weapon.reserve)
	update_score(0, 0)


func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	crosshair = Crosshair.new()
	crosshair.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(crosshair)

	var top_left := VBoxContainer.new()
	top_left.position = Vector2(24.0, 20.0)
	top_left.add_theme_constant_override("separation", 8)
	root.add_child(top_left)

	health_value = _make_label(26, Color(1.0, 1.0, 1.0))
	ammo_value = _make_label(26, Color(1.0, 0.88, 0.55))
	score_value = _make_label(24, Color(0.75, 0.9, 1.0))
	reload_bar = ProgressBar.new()
	reload_bar.custom_minimum_size = Vector2(190.0, 8.0)
	reload_bar.max_value = 1.0
	reload_bar.show_percentage = false
	reload_bar.visible = false
	top_left.add_child(health_value)
	top_left.add_child(ammo_value)
	top_left.add_child(score_value)
	top_left.add_child(reload_bar)

	message_label = _make_label(72, Color(1.0, 0.95, 0.85))
	message_label.visible = false
	message_label.set_anchors_preset(Control.PRESET_CENTER)
	message_label.position = Vector2(-220.0, -40.0)
	message_label.custom_minimum_size = Vector2(440.0, 120.0)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	root.add_child(message_label)


func _make_label(size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.75))
	label.add_theme_constant_override("outline_size", 8)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func update_score(player_score: int, bot_score: int) -> void:
	if score_value != null:
		score_value.text = "YOU %d   -   %d BOT" % [player_score, bot_score]


func show_message(text: String, _final: bool) -> void:
	message_label.text = text
	message_label.visible = true


func _on_health_changed(current: int, maximum: int) -> void:
	if health_value == null:
		return
	health_value.text = "HP %d / %d" % [current, maximum]
	health_value.add_theme_color_override("font_color", Color(0.95, 0.25, 0.2) if current <= 40 else Color(1.0, 1.0, 1.0))


func _on_ammo_changed(magazine: int, reserve: int) -> void:
	if ammo_value == null:
		return
	ammo_value.text = "%d / %d" % [magazine, reserve]
	if reload_bar != null:
		reload_bar.visible = false


func _on_reload_started() -> void:
	ammo_value.text = "RELOADING"
	if reload_bar != null:
		reload_bar.visible = true
