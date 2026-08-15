extends Node3D


const MAP_SIZE_X := 44.0
const WIN_SCORE := 10
const PLAYER_RESPAWN_DELAY := 2.5
const BOT_RESPAWN_DELAY := 2.0

var map_builder: MapBuilder
var player: Player
var bot: DuelBot
var hud: HUD
var player_score := 0
var bot_score := 0
var match_over := false
var respawn_queued := ""
var respawn_timer := 0.0


func _ready() -> void:
	map_builder = MapBuilder.new()
	add_child(map_builder)
	_spawn_player()
	_spawn_bot()
	hud = HUD.new()
	add_child(hud)
	hud.setup(player, bot)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().quit()


func _physics_process(delta: float) -> void:
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
		Vector3(11.0, 0.0, 4.0),
		Vector3(20.0, 0.0, 4.0),
		Vector3(20.0, 0.0, -4.0),
		Vector3(11.0, 0.0, -4.0),
		Vector3(2.0, 0.0, -4.0),
		Vector3(2.0, 0.0, 4.0),
	])
	bot.add_to_group("damageable")
	bot.died.connect(_on_bot_died)


func _on_player_died() -> void:
	if match_over:
		return
	bot_score += 1
	hud.update_score(player_score, bot_score)
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
