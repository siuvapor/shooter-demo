extends Node3D


const MAP_SIZE_X := 80.0
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
var zombie_mode := false
var zombie_spawn_timer := 0.0
var _tombstones: Array[Tombstone] = []
var _pending_tombstones: Array[Dictionary] = []
var _zombies: Array[ZombieEnemy] = []


func _ready() -> void:
	var settings := get_node_or_null("/root/Settings")
	zombie_mode = settings != null and settings.game_mode == "zombie"
	map_builder = MapBuilderTower.new()
	add_child(map_builder)
	_spawn_ropes()
	_spawn_jump_pads()
	_spawn_wormholes()
	_spawn_player()
	if zombie_mode:
		zombie_spawn_timer = 0.5
	else:
		_spawn_bot()
	hud = HUD.new()
	add_child(hud)
	hud.setup(player, bot)
	hud.set_zombie_mode(zombie_mode)


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
		if zombie_mode:
			zombie_spawn_timer -= delta
			if zombie_spawn_timer <= 0.0 and _zombies.size() < 10:
				_spawn_zombie()
				zombie_spawn_timer = 5.0
		return
	respawn_timer -= delta
	if respawn_timer <= 0.0:
		_finish_respawn()

	if zombie_mode:
		zombie_spawn_timer -= delta
		if zombie_spawn_timer <= 0.0 and _zombies.size() < 10:
			_spawn_zombie()
			zombie_spawn_timer = 5.0


func _spawn_player() -> void:
	player = Player.new()
	player.name = "Player"
	add_child(player)
	player.global_position = Vector3(-MAP_SIZE_X * 0.5 + 4.0, 0.0, 0.0)
	player.rotation.y = -PI * 0.5
	player.add_to_group("damageable")
	player.died.connect(_on_player_died)


func _spawn_bot() -> void:
	bot = DuelBot.new()
	bot.name = "DuelBot"
	add_child(bot)
	bot.global_position = Vector3(MAP_SIZE_X * 0.5 - 4.0, 0.0, 0.0)
	bot.rotation.y = PI * 0.5
	bot.set_player(player)
	bot.set_waypoints([
		Vector3(-32.0, 0.0, 9.0),
		Vector3(36.0, 0.0, 9.0),
		Vector3(36.0, 0.0, -9.0),
		Vector3(-32.0, 0.0, -9.0),
		Vector3(-4.0, 0.0, -9.0),
		Vector3(-4.0, 0.0, 9.0),
	])
	bot.add_to_group("damageable")
	bot.died.connect(_on_bot_died)


func _on_player_died() -> void:
	if match_over:
		return
	if zombie_mode:
		match_over = true
		hud.show_message("DEFEAT", true)
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


func _on_zombie_died(zombie: ZombieEnemy) -> void:
	player_score += 1
	hud.update_score(player_score, bot_score)
	_zombies.erase(zombie)


func _spawn_zombie() -> void:
	var layer := 0
	if player.global_position.y > 5.5:
		layer = 2
	elif player.global_position.y > 2.5:
		layer = 1
	var spawn_points: Array[Vector3] = []
	match layer:
		2:
			spawn_points = [
				Vector3(-18.0, 6.1, 10.0),
				Vector3(16.0, 6.1, -10.0),
				Vector3(0.0, 6.1, 0.0),
				Vector3(18.0, 6.1, 8.0),
			]
		1:
			spawn_points = [
				Vector3(-20.0, 3.1, 12.0),
				Vector3(20.0, 3.1, -12.0),
				Vector3(0.0, 3.1, -14.0),
				Vector3(-10.0, 3.1, 10.0),
			]
		_:
			spawn_points = [
				Vector3(-34.0, 0.0, 12.0),
				Vector3(34.0, 0.0, -12.0),
				Vector3(-20.0, 0.0, 18.0),
				Vector3(20.0, 0.0, -18.0),
				Vector3(0.0, 0.0, 22.0),
			]
	var zombie := ZombieEnemy.new()
	zombie.name = "Zombie"
	add_child(zombie)
	zombie.global_position = spawn_points[randi() % spawn_points.size()]
	zombie.setup(player)
	zombie.add_to_group("damageable")
	zombie.died.connect(_on_zombie_died.bind(zombie))
	_zombies.append(zombie)


func _finish_respawn() -> void:
	var who := respawn_queued
	respawn_queued = ""
	if who == "player":
		player.respawn_at(Vector3(-MAP_SIZE_X * 0.5 + 4.0, 0.0, 0.0), -PI * 0.5)
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
	rope_one.name = "RopeVerticalGroundSecond"
	add_child(rope_one)
	rope_one.setup(Vector3(20.0, 0.0, 12.0), Vector3(20.0, 3.1, 12.0), Color(0.95, 0.6, 0.2))

	var rope_two := RopeTeleporter.new()
	rope_two.name = "RopeHorizontalSecond"
	add_child(rope_two)
	rope_two.setup(Vector3(-18.0, 3.1, -12.0), Vector3(18.0, 3.1, -12.0), Color(0.35, 0.75, 1.0))

	var rope_three := RopeTeleporter.new()
	rope_three.name = "RopeVerticalSecondThird"
	add_child(rope_three)
	rope_three.setup(Vector3(-20.0, 3.1, -10.0), Vector3(-20.0, 6.1, -10.0), Color(0.35, 0.9, 1.0))


func _spawn_jump_pads() -> void:
	var pad_one := JumpPad.new()
	pad_one.name = "JumpPadGround"
	add_child(pad_one)
	pad_one.global_position = Vector3(26.0, 0.1, -12.0)
	pad_one.setup(13.5, Color(0.95, 0.7, 0.2))

	var pad_two := JumpPad.new()
	pad_two.name = "JumpPadSecond"
	add_child(pad_two)
	pad_two.global_position = Vector3(14.0, 3.1, 10.0)
	pad_two.setup(14.0, Color(0.35, 0.9, 1.0))


func _spawn_wormholes() -> void:
	var portal_a := Wormhole.new()
	portal_a.name = "WormholeGround"
	add_child(portal_a)
	portal_a.global_position = Vector3(-35.0, 1.0, 0.0)
	portal_a.setup(Color(0.85, 0.25, 1.0))

	var portal_b := Wormhole.new()
	portal_b.name = "WormholeThird"
	add_child(portal_b)
	portal_b.global_position = Vector3(18.0, 6.4, 0.0)
	portal_b.setup(Color(0.25, 0.9, 1.0))
	portal_a.link_to(portal_b)
