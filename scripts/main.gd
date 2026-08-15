extends Node3D


const MAP_SIZE_X := 44.0
const WIN_SCORE := 10
const PLAYER_RESPAWN_DELAY := 2.5
const BOT_RESPAWN_DELAY := 2.0

var map_builder: MapBuilderTower
var player: Player
var bot: DuelBot
var hud: HUD
var player_score := 0
var bot_score := 0
var match_over := false
var respawn_queued := ""
var respawn_timer := 0.0
var _tombstones: Array[Tombstone] = []
var _pending_tombstones: Array[Dictionary] = []


func _ready() -> void:
	map_builder = MapBuilderTower.new()
	add_child(map_builder)
	_spawn_ropes()
	_spawn_player()
	_spawn_bot()
	hud = HUD.new()
	add_child(hud)
	hud.setup(player, bot)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().quit()


func _physics_process(delta: float) -> void:
	for i in range(_pending_tombstones.size() - 1, -1, -1):
		var entry: Dictionary = _pending_tombstones[i]
		entry["timer"] = entry["timer"] - delta
		if entry["timer"] <= 0.0:
			_pending_tombstones.remove_at(i)
			_spawn_tombstone(entry["pos"], entry["label"], entry["color"])
	if match_over or respawn_queued == "":
		return
	respawn_timer -= delta
	if respawn_timer <= 0.0:
		_finish_respawn()


func _spawn_player() -> void:
	player = Player.new()
	player.name = "Player"
	add_child(player)
	player.global_position = Vector3(-MAP_SIZE_X * 0.5 + 3.0, 0.0, 0.0)
	player.rotation.y = -PI * 0.5
	player.add_to_group("damageable")
	player.died.connect(_on_player_died)


func _spawn_bot() -> void:
	bot = DuelBot.new()
	bot.name = "DuelBot"
	add_child(bot)
	bot.global_position = Vector3(MAP_SIZE_X * 0.5 - 3.0, 0.0, 0.0)
	bot.rotation.y = PI * 0.5
	bot.set_player(player)
	bot.set_waypoints([
		Vector3(-14.0, 0.0, 9.0),
		Vector3(18.0, 0.0, 9.0),
		Vector3(18.0, 0.0, -9.0),
		Vector3(-14.0, 0.0, -9.0),
		Vector3(-2.0, 0.0, -9.0),
		Vector3(-2.0, 0.0, 9.0),
	])
	bot.add_to_group("damageable")
	bot.died.connect(_on_bot_died)


func _on_player_died() -> void:
	if match_over:
		return
	bot_score += 1
	hud.update_score(player_score, bot_score)
	_queue_tombstone(player.global_position, "PLAYER", Color(0.25, 0.55, 0.9))
	if bot_score >= WIN_SCORE:
		match_over = true
		hud.show_message("DEFEAT", true)
	else:
		respawn_queued = "player"
		respawn_timer = PLAYER_RESPAWN_DELAY


func _on_bot_died() -> void:
	if match_over:
		return
	player_score += 1
	hud.update_score(player_score, bot_score)
	_queue_tombstone(bot.global_position, "BOT", Color(0.9, 0.3, 0.25))
	if player_score >= WIN_SCORE:
		match_over = true
		hud.show_message("VICTORY", true)
	else:
		respawn_queued = "bot"
		respawn_timer = BOT_RESPAWN_DELAY


func _finish_respawn() -> void:
	var who := respawn_queued
	respawn_queued = ""
	if who == "player":
		player.respawn_at(Vector3(-MAP_SIZE_X * 0.5 + 3.0, 0.0, 0.0), -PI * 0.5)
	elif who == "bot":
		bot.respawn()


func _queue_tombstone(pos: Vector3, label: String, accent: Color) -> void:
	_pending_tombstones.append({
		"pos": pos,
		"label": label,
		"color": accent,
		"timer": 1.0
	})


func _spawn_tombstone(pos: Vector3, label: String, accent: Color) -> void:
	var tombstone := Tombstone.new()
	tombstone.name = "Tombstone"
	add_child(tombstone)
	tombstone.global_position = pos + Vector3(0.0, 0.0, 0.25)
	tombstone.rotation.y = randf_range(-0.4, 0.4)
	tombstone.setup(label, accent)
	_tombstones.append(tombstone)
	while _tombstones.size() > 8:
		var old: Tombstone = _tombstones.pop_front()
		if is_instance_valid(old):
			old.queue_free()


func _spawn_ropes() -> void:
	var rope_one := RopeTeleporter.new()
	rope_one.name = "RopeGroundToSecond"
	add_child(rope_one)
	rope_one.setup(Vector3(11.0, 0.0, -10.0), Vector3(11.0, 3.1, 10.0), Color(0.95, 0.6, 0.2))

	var rope_two := RopeTeleporter.new()
	rope_two.name = "RopeSecondToThird"
	add_child(rope_two)
	rope_two.setup(Vector3(-10.0, 3.1, 10.0), Vector3(-8.0, 6.1, -10.0), Color(0.35, 0.75, 1.0))
