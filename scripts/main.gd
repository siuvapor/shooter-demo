extends Node3D


const MAP_SIZE_X := 80.0
const WIN_SCORE := 10
const PLAYER_RESPAWN_DELAY := 2.5
const BOT_RESPAWN_DELAY := 0.0
const QUICKSCOPE_DURATION := 60.0
const BOT_SPAWN_POINTS := [
	Vector3(-34.0, 0.0, 14.0),
	Vector3(-30.0, 0.0, -16.0),
	Vector3(-16.0, 0.0, -20.0),
	Vector3(2.0, 0.0, -22.0),
	Vector3(20.0, 0.0, -20.0),
	Vector3(34.0, 0.0, -12.0),
	Vector3(34.0, 0.0, 14.0),
	Vector3(18.0, 0.0, 20.0),
	Vector3(0.0, 0.0, 22.0),
	Vector3(-18.0, 0.0, 20.0),
]
const QUICKSCOPE_BOT_SPAWN_POINTS := [
	Vector3(22.0, 0.0, 0.0),
	Vector3(18.0, 0.0, -5.0),
	Vector3(18.0, 0.0, 5.0),
	Vector3(24.0, 0.0, -2.0),
	Vector3(24.0, 0.0, 2.0),
]

var map_builder: Node3D
var player: Player
var bot: DuelBot
var _bots: Array[DuelBot] = []
var _respawn_bot: DuelBot
var hud: HUD
var player_score := 0
var bot_score := 0
var match_over := false
var respawn_queued := ""
var respawn_timer := 0.0
var zombie_mode := false
var quickscope_mode := false
var parkour_mode := false
var quickscope_time_left := QUICKSCOPE_DURATION
var zombie_spawn_timer := 0.0
var zombie_spawn_interval := 5.0
var _tombstones: Array[Tombstone] = []
var _pending_tombstones: Array[Dictionary] = []
var _zombies: Array[ZombieEnemy] = []
var stats := {
	"score": 0.0,
	"damage": 0,
	"headshots": 0,
	"hits": 0,
	"shots": 0,
	"kills": 0,
	"deaths": 0
}


func _ready() -> void:
	var settings := get_node_or_null("/root/Settings")
	zombie_mode = settings != null and settings.game_mode == "zombie"
	quickscope_mode = settings != null and settings.game_mode == "quickscope"
	parkour_mode = settings != null and settings.game_mode == "parkour"
	var map_id := "tower"
	if settings != null:
		map_id = settings.selected_map
	if quickscope_mode:
		map_id = "quickscope"
	elif parkour_mode:
		map_id = "parkour"
	match map_id:
		"quickscope":
			map_builder = MapBuilderQuickscope.new()
		"parkour":
			map_builder = MapBuilderParkour.new()
		"field":
			map_builder = MapBuilderField.new()
		_:
			map_builder = MapBuilderTower.new()
	add_child(map_builder)
	if map_id == "tower":
		_spawn_ropes()
		_spawn_jump_pads()
		_spawn_wormholes()
	_spawn_player()
	if zombie_mode:
		zombie_spawn_interval = _zombie_interval()
		zombie_spawn_timer = 0.5
		if _zombie_difficulty() == "insane":
			for i in range(10):
				_spawn_zombie()
	elif not parkour_mode:
		_spawn_bots(1 if quickscope_mode else _bot_count())
	hud = HUD.new()
	add_child(hud)
	hud.setup(player, bot)
	hud.set_zombie_mode(zombie_mode)
	if quickscope_mode:
		hud.update_time(quickscope_time_left)
	player.weapon.fired.connect(_on_shot_fired)
	player.weapon.damage_dealt.connect(_on_damage_dealt)
	player.weapon.kill_confirmed.connect(_on_kill_confirmed)


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
	if quickscope_mode and not match_over:
		quickscope_time_left = maxf(0.0, quickscope_time_left - delta)
		hud.update_time(quickscope_time_left)
		if quickscope_time_left <= 0.0:
			match_over = true
			hud.show_message("TIME UP", true)
			_show_end_stats()
	if parkour_mode and player != null and player.global_position.y < -18.0:
		player.respawn_at(Vector3(-34.0, 0.0, 0.0), -PI * 0.5)
	if match_over or respawn_queued == "":
		if zombie_mode:
			zombie_spawn_timer -= delta
			if zombie_spawn_timer <= 0.0 and _zombies.size() < 20:
				_spawn_zombie()
				zombie_spawn_timer = zombie_spawn_interval
		return
	respawn_timer -= delta
	if respawn_timer <= 0.0:
		_finish_respawn()

	if zombie_mode:
		zombie_spawn_timer -= delta
		if zombie_spawn_timer <= 0.0 and _zombies.size() < 20:
			_spawn_zombie()
			zombie_spawn_timer = zombie_spawn_interval


func _spawn_player() -> void:
	player = Player.new()
	player.name = "Player"
	add_child(player)
	if quickscope_mode:
		player.global_position = Vector3(-28.0, 0.0, 0.0)
	elif parkour_mode:
		player.global_position = Vector3(-34.0, 0.0, 0.0)
	else:
		player.global_position = Vector3(-MAP_SIZE_X * 0.5 + 4.0, 0.0, 0.0)
	player.rotation.y = -PI * 0.5
	player.add_to_group("damageable")
	player.died.connect(_on_player_died)


func _spawn_bots(count: int) -> void:
	_bots.clear()
	var difficulty := _difficulty()
	var spawn_pool: Array = QUICKSCOPE_BOT_SPAWN_POINTS.duplicate() if quickscope_mode else BOT_SPAWN_POINTS.duplicate()
	spawn_pool.shuffle()
	for i in range(count):
		var spawn: Dictionary = _bot_spawn_data(spawn_pool, i)
		var new_bot := DuelBot.new()
		new_bot.name = "DuelBot%d" % (i + 1)
		add_child(new_bot)
		new_bot.global_position = spawn["pos"]
		new_bot.rotation.y = spawn["yaw"]
		new_bot.set_spawn_point(spawn["pos"], spawn["yaw"])
		new_bot.set_player(player)
		new_bot.set_waypoints([
			Vector3(-32.0, 0.0, 9.0),
			Vector3(36.0, 0.0, 9.0),
			Vector3(36.0, 0.0, -9.0),
			Vector3(-32.0, 0.0, -9.0),
			Vector3(-4.0, 0.0, -9.0),
			Vector3(-4.0, 0.0, 9.0),
		])
		if difficulty == "easy":
			new_bot.aim_error = 0.075
		if difficulty == "insane":
			new_bot.speed_multiplier = 1.5
		if quickscope_mode:
			new_bot.set_quickscope_mode(true)
		new_bot.add_to_group("damageable")
		new_bot.died.connect(_on_bot_died.bind(new_bot))
		_bots.append(new_bot)
	if not _bots.is_empty():
		bot = _bots[0]


func _on_player_died() -> void:
	if match_over:
		return
	stats["deaths"] += 1
	if zombie_mode:
		match_over = true
		hud.show_message("DEFEAT", true)
		_show_end_stats()
		return
	bot_score += 1
	hud.update_score(player_score, bot_score)
	_queue_tombstone(player.global_position, "PLAYER", Color(0.25, 0.55, 0.9))
	if bot_score >= WIN_SCORE:
		match_over = true
		hud.show_message("DEFEAT", true)
		_show_end_stats()
	else:
		respawn_queued = "player"
		respawn_timer = PLAYER_RESPAWN_DELAY


func _on_bot_died(bot_instance: DuelBot) -> void:
	if match_over:
		return
	player_score += 1
	hud.update_score(player_score, bot_score)
	if player_score >= _win_score():
		match_over = true
		hud.show_message("VICTORY", true)
		_show_end_stats()
	else:
		if not quickscope_mode:
			_queue_tombstone(bot_instance.global_position, "BOT", Color(0.9, 0.3, 0.25))
		_respawn_bot = bot_instance
		respawn_queued = "bot"
		respawn_timer = BOT_RESPAWN_DELAY


func _on_zombie_died(zombie: ZombieEnemy) -> void:
	_zombies.erase(zombie)
	hud.update_score(player_score, bot_score)


func _on_shot_fired() -> void:
	stats["shots"] += 1


func _on_damage_dealt(amount: int, zone: String, weapon_id: String) -> void:
	stats["damage"] += amount
	stats["hits"] += 1
	if zone == "head":
		stats["headshots"] += 1
	if zombie_mode:
		stats["score"] += _zombie_hit_points(weapon_id, zone) * _zombie_score_multiplier()


func _on_kill_confirmed(weapon_id: String) -> void:
	stats["kills"] += 1
	if zombie_mode:
		if weapon_id == "knife":
			stats["score"] += 10.0 * _zombie_score_multiplier()
		elif weapon_id == "lockon":
			stats["score"] -= 2.0 * _zombie_score_multiplier()


func _zombie_hit_points(weapon_id: String, zone: String) -> float:
	var head := zone == "head"
	match weapon_id:
		"vandal":
			return 5.0 if head else 1.0
		"phantom":
			return 4.0 if head else 0.5
		"operator":
			return 8.0 if head else 5.0
		"sheriff":
			return 6.0 if head else 2.0
	return 0.0


func _zombie_interval() -> float:
	match _zombie_difficulty():
		"easy":
			return 5.0
		"hard":
			return 1.0
		"insane":
			return 0.5
	return 3.0


func _zombie_score_multiplier() -> float:
	match _zombie_difficulty():
		"easy":
			return 1.0
		"hard":
			return 2.0
		"insane":
			return 4.0
	return 1.5


func _zombie_difficulty() -> String:
	var settings := get_node_or_null("/root/Settings")
	return settings.zombie_difficulty if settings != null else "normal"


func _show_end_stats() -> void:
	if not zombie_mode:
		stats["score"] = float(player_score)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hud.show_end_stats(stats, zombie_mode)


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
		if is_instance_valid(_respawn_bot):
			var spawn_pool: Array = QUICKSCOPE_BOT_SPAWN_POINTS.duplicate() if quickscope_mode else BOT_SPAWN_POINTS.duplicate()
			spawn_pool.shuffle()
			var spawn: Dictionary = _bot_spawn_data(spawn_pool, 0)
			_respawn_bot.set_spawn_point(spawn["pos"], spawn["yaw"])
			_respawn_bot.respawn()


func _bot_spawn_data(pool: Array, slot: int) -> Dictionary:
	var pos: Vector3 = pool[slot % pool.size()]
	var to_player := player.global_position - pos
	return {
		"pos": pos,
		"yaw": atan2(-to_player.x, -to_player.z)
	}


func _bot_count() -> int:
	match _difficulty():
		"hard":
			return 2
		"insane":
			return 3
	return 1


func _win_score() -> int:
	var difficulty := _difficulty()
	return 20 if difficulty == "hard" or difficulty == "insane" else 10


func _difficulty() -> String:
	var settings := get_node_or_null("/root/Settings")
	return settings.zombie_difficulty if settings != null else "normal"


func _queue_tombstone(pos: Vector3, label: String, accent: Color) -> void:
	if quickscope_mode:
		return
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
