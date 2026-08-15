class_name Weapon
extends Node3D


signal ammo_changed(magazine: int, reserve: int)
signal fired
signal reload_started
signal reload_finished
signal weapon_selected(weapon_id: String)
signal inspect_started
signal damage_dealt(amount: int, zone: String, weapon_id: String)
signal kill_confirmed(weapon_id: String)

const BASE_FOV := 70.0
const RANGE := 300.0
const RECOIL_RECOVERY_TIME := 0.375
const INSPECT_DURATION := 1.2

const WEAPON_ORDER := ["vandal", "phantom", "operator", "sheriff", "knife", "lockon"]

const WEAPON_DEFS := {
	"vandal": {
		"name": "Vandal",
		"type": "rifle",
		"color": Color(0.78, 0.24, 0.20),
		"damage_head": 160,
		"damage_body": 40,
		"damage_leg": 34,
		"fire_rate": 9.75,
		"ads_fire_rate": 8.775,
		"magazine_size": 25,
		"reserve_size": 50,
		"reload_time": 2.5,
		"ads_zoom": 1.25,
		"spread": 0.25,
		"spread_crouch": 0.21,
		"spread_max": 1.0,
		"spread_max_crouch": 0.85,
		"spread_ads": 0.157,
		"spread_ads_crouch": 0.13,
		"spread_ads_max": 1.02,
		"spread_ads_max_crouch": 0.87
	},
	"phantom": {
		"name": "Phantom",
		"type": "rifle",
		"color": Color(0.35, 0.62, 0.92),
		"damage_head": 156,
		"damage_body": 39,
		"damage_leg": 33,
		"fire_rate": 11.0,
		"ads_fire_rate": 9.9,
		"magazine_size": 30,
		"reserve_size": 90,
		"reload_time": 2.5,
		"ads_zoom": 1.25,
		"spread": 0.2,
		"spread_crouch": 0.17,
		"spread_max": 0.9,
		"spread_max_crouch": 0.77,
		"spread_ads": 0.13,
		"spread_ads_crouch": 0.11,
		"spread_ads_max": 0.9,
		"spread_ads_max_crouch": 0.77
	},
	"operator": {
		"name": "Operator",
		"type": "sniper",
		"color": Color(0.95, 0.76, 0.34),
		"damage_head": 255,
		"damage_body": 150,
		"damage_leg": 127,
		"fire_rate": 0.75,
		"ads_fire_rate": 0.75,
		"magazine_size": 5,
		"reserve_size": 10,
		"reload_time": 3.7,
		"ads_zoom": 2.5,
		"spread": 0.02,
		"spread_crouch": 0.02,
		"spread_max": 0.35,
		"spread_max_crouch": 0.3,
		"spread_ads": 0.0,
		"spread_ads_crouch": 0.0,
		"spread_ads_max": 0.15,
		"spread_ads_max_crouch": 0.13
	},
	"sheriff": {
		"name": "Sheriff",
		"type": "pistol",
		"color": Color(0.68, 0.56, 0.42),
		"damage_head": 159,
		"damage_body": 55,
		"damage_leg": 46,
		"fire_rate": 4.0,
		"ads_fire_rate": 3.6,
		"magazine_size": 6,
		"reserve_size": 30,
		"reload_time": 2.25,
		"ads_zoom": 1.5,
		"spread": 0.35,
		"spread_crouch": 0.3,
		"spread_max": 1.5,
		"spread_max_crouch": 1.28,
		"spread_ads": 0.2,
		"spread_ads_crouch": 0.17,
		"spread_ads_max": 1.0,
		"spread_ads_max_crouch": 0.85
	},
	"knife": {
		"name": "Butterfly Knife",
		"type": "melee",
		"color": Color(0.88, 0.62, 0.24),
		"damage_head": 150,
		"damage_body": 75,
		"damage_leg": 50,
		"fire_rate": 2.5,
		"ads_fire_rate": 2.5,
		"magazine_size": 0,
		"reserve_size": 0,
		"reload_time": 0.0,
		"ads_zoom": 1.0,
		"spread": 0.0,
		"spread_crouch": 0.0,
		"spread_max": 0.0,
		"spread_max_crouch": 0.0,
		"spread_ads": 0.0,
		"spread_ads_crouch": 0.0,
		"spread_ads_max": 0.0,
		"spread_ads_max_crouch": 0.0,
		"range": 2.4
	},
	"lockon": {
		"name": "Lock Rifle",
		"type": "special",
		"color": Color(0.95, 0.35, 1.0),
		"damage_head": 200,
		"damage_body": 60,
		"damage_leg": 50,
		"fire_rate": 6.0,
		"ads_fire_rate": 6.0,
		"magazine_size": 12,
		"reserve_size": 48,
		"reload_time": 2.2,
		"ads_zoom": 1.0,
		"spread": 0.0,
		"spread_crouch": 0.0,
		"spread_max": 0.0,
		"spread_max_crouch": 0.0,
		"spread_ads": 0.0,
		"spread_ads_crouch": 0.0,
		"spread_ads_max": 0.0,
		"spread_ads_max_crouch": 0.0,
		"range": 220.0
	}
}

const GUNSHOT_SOUND := preload("res://assets/audio/gunshot.wav")
const RELOAD_START_SOUND := preload("res://assets/audio/reload_start.wav")
const RELOAD_END_SOUND := preload("res://assets/audio/reload_end.wav")
const HIT_SOUND := preload("res://assets/audio/hitmarker.wav")
const HEADSHOT_SOUND := preload("res://assets/audio/headshot.wav")
const SLASH_SOUND := preload("res://assets/audio/slash.wav")

var player: Player
var camera: Camera3D
var current_weapon_id := "vandal"
var current_def: Dictionary
var magazine := 0
var reserve := 0
var reloading := false
var reload_timer := 0.0
var fire_cooldown := 0.0
var spread_bonus := 0.0
var spray_index := 0
var recoil_pitch := 0.0
var recoil_yaw := 0.0
var recoil_target_pitch := 0.0
var recoil_target_yaw := 0.0
var recovery_timer := 0.0
var ads_amount := 0.0
var ads_target := 0.0
var inspect_timer := 0.0
var slash_timer := 0.0
var slash_duration := 0.42
var slash_mode := ""
var bolt_timer := 0.0
var bolt_duration := 1.0
var sniper_scope_on := false
var _rmb_was_down := false
var _lock_target: Node3D
var _ammo: Dictionary = {}
var _sfx: AudioStreamPlayer
var _viewmodel_root: Node3D
var _magazine_mesh: MeshInstance3D
var _mag_done := false
var _viewmodel_nodes: Array[Node3D] = []
var _built := false


func setup(owner_player: Player, cam: Camera3D) -> void:
	player = owner_player
	camera = cam
	if not _built:
		_sfx = AudioStreamPlayer.new()
		_sfx.name = "Sfx"
		_sfx.max_polyphony = 4
		add_child(_sfx)
		_viewmodel_root = Node3D.new()
		_viewmodel_root.name = "ViewModelRoot"
		add_child(_viewmodel_root)
		for id in WEAPON_ORDER:
			_ammo[id] = {
				"magazine": WEAPON_DEFS[id]["magazine_size"],
				"reserve": WEAPON_DEFS[id]["reserve_size"]
			}
		_built = true
	var settings := get_node_or_null("/root/Settings")
	if settings != null and settings.game_mode == "quickscope":
		select_weapon_id("operator", true)
	else:
		select_weapon_id("vandal", true)


func _process(delta: float) -> void:
	if player == null or camera == null:
		return
	_update_ads(delta)
	_update_recoil(delta)
	_update_spray(delta)
	_update_viewmodel(delta)
	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	if inspect_timer > 0.0:
		inspect_timer = maxf(0.0, inspect_timer - delta)
	if slash_timer > 0.0:
		slash_timer = maxf(0.0, slash_timer - delta)
	if bolt_timer > 0.0:
		bolt_timer = maxf(0.0, bolt_timer - delta)
	if reloading:
		reload_timer -= delta
		if reload_timer <= 0.0:
			_finish_reload()
	if player.dead:
		return
	var rmb_down := Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	if rmb_down and not _rmb_was_down:
		if current_def["type"] == "melee":
			if fire_cooldown <= 0.0:
				_heavy_melee_attack()
		elif current_def["type"] == "sniper":
			if bolt_timer <= 0.0:
				sniper_scope_on = not sniper_scope_on
	_rmb_was_down = rmb_down
	if current_def["type"] == "sniper":
		ads_target = 1.0 if sniper_scope_on else 0.0
	elif current_def["type"] == "special" or current_def["type"] == "melee":
		ads_target = 0.0
	else:
		ads_target = 1.0 if rmb_down and current_def["type"] != "melee" else 0.0
	if Input.is_physical_key_pressed(KEY_1):
		select_weapon_id("vandal")
	elif Input.is_physical_key_pressed(KEY_2):
		select_weapon_id("phantom")
	elif Input.is_physical_key_pressed(KEY_3):
		select_weapon_id("operator")
	elif Input.is_physical_key_pressed(KEY_4):
		select_weapon_id("sheriff")
	elif Input.is_physical_key_pressed(KEY_5):
		select_weapon_id("knife")
	elif Input.is_physical_key_pressed(KEY_6):
		select_weapon_id("lockon")
	if Input.is_physical_key_pressed(KEY_F):
		start_inspect()
	_update_lockon()
	if Input.is_physical_key_pressed(KEY_R):
		start_reload()
	if magazine == 0 and not reloading and current_def["type"] != "melee":
		start_reload()
	var can_fire: bool = current_def["type"] == "melee" or magazine > 0
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and fire_cooldown <= 0.0 and not reloading and can_fire:
		fire()


func fire() -> void:
	inspect_timer = 0.0
	slash_timer = 0.0
	if current_def["type"] == "melee":
		_melee_attack()
		return

	var def: Dictionary = current_def
	var is_ads := ads_amount > 0.5
	fire_cooldown = 1.0 / (def["ads_fire_rate"] if is_ads else def["fire_rate"])
	if _is_quickscope_mode() and current_weapon_id == "operator":
		sniper_scope_on = false
		bolt_timer = fire_cooldown
		bolt_duration = fire_cooldown
	if not _has_infinite_magazine():
		magazine -= 1
	_ammo[current_weapon_id] = {"magazine": magazine, "reserve": reserve}
	ammo_changed.emit(magazine, reserve)

	var from := camera.global_position
	var direction := _shoot_direction(calculate_spread())
	if current_def["type"] == "special" and _lock_target != null:
		var head: Vector3 = _lock_target.global_position + Vector3(0.0, 1.55, 0.0)
		direction = (head - from).normalized()
	var to := from + direction * RANGE
	var query := PhysicsRayQueryParameters3D.create(from, to, 0b1111)
	query.exclude = [player.get_rid()]
	var result := camera.get_world_3d().direct_space_state.intersect_ray(query)
	var end := to
	if result:
		end = result.position
		_resolve_hit(result)

	var world := get_tree().current_scene
	Fx.spawn_tracer(world, from + camera.global_transform.basis.z * -0.4, end, Color(1.0, 0.82, 0.32))
	Fx.spawn_muzzle_flash(world, from + camera.global_transform.basis.z * -0.45)
	_play_sound(GUNSHOT_SOUND, -5.0, randf_range(0.95, 1.05))
	_add_recoil()
	spray_index += 1
	spread_bonus = minf(spread_bonus + 0.09, 1.6)
	fired.emit()


func _melee_attack(heavy := false) -> void:
	var def: Dictionary = current_def
	inspect_timer = 0.0
	slash_timer = 0.55 if heavy else 0.42
	slash_duration = slash_timer
	slash_mode = "stab" if heavy else ("slash_b" if randi() % 2 == 0 else "slash_a")
	fire_cooldown = 1.0 / def["fire_rate"]
	_play_sound(SLASH_SOUND, -4.0, randf_range(0.95, 1.05))
	var from := camera.global_position
	var forward := -camera.global_transform.basis.z
	var reach: float = def.get("range", 2.4)
	var to: Vector3 = from + forward * reach
	var query := PhysicsRayQueryParameters3D.create(from, to, 0b1111)
	query.exclude = [player.get_rid()]
	var result := camera.get_world_3d().direct_space_state.intersect_ray(query)
	var end: Vector3 = to
	if result:
		end = result.position
		_resolve_hit(result, 2.0 if heavy else 1.0)
	var world := get_tree().current_scene
	Fx.spawn_tracer(world, from + forward * 0.3, end, Color(0.95, 0.88, 0.72))
	fired.emit()


func _heavy_melee_attack() -> void:
	_melee_attack(true)


func _resolve_hit(result: Dictionary, damage_multiplier := 1.0) -> void:
	var collider: Node = result.collider
	if collider != null and collider.is_in_group("destructible") and collider.has_method("take_damage"):
		var body_damage: int = int(current_def["damage_body"] * damage_multiplier)
		collider.take_damage(body_damage, "body", result.position, result.normal, player)
		return
	if collider == null or not collider.is_in_group("damageable"):
		Fx.spawn_impact(get_tree().current_scene, result.position, result.normal)
		return
	if collider.has_method("take_damage") and collider.get("shield_active") == true:
		Fx.spawn_impact(get_tree().current_scene, result.position, result.normal, Color(0.4, 0.8, 1.0))
		return
	var zone := "body"
	if collider.has_method("resolve_hit_zone"):
		zone = collider.resolve_hit_zone(result.position)
	var base_damage: int = current_def["damage_head"] if zone == "head" else current_def["damage_body"] if zone == "body" else current_def["damage_leg"]
	var damage: int = int(base_damage * damage_multiplier)
	var was_dead: bool = collider.get("dead") == true
	if was_dead:
		return
	if collider.has_method("take_damage"):
		collider.take_damage(damage, zone, result.position, result.normal, player)
	damage_dealt.emit(damage, zone, current_weapon_id)
	if collider.get("dead") == true:
		kill_confirmed.emit(current_weapon_id)
	player.hit_marker.emit(zone)
	_play_sound(HEADSHOT_SOUND if zone == "head" else HIT_SOUND, -3.0, randf_range(0.95, 1.05))
	var color := Color(1.0, 0.3, 0.25) if zone == "head" else Color(1.0, 1.0, 1.0)
	Fx.spawn_damage_number(get_tree().current_scene, result.position, str(damage), color)


func _shoot_direction(spread_degrees: float) -> Vector3:
	var basis := camera.global_transform.basis
	var forward := -basis.z
	var right := basis.x
	var up := basis.y
	var spread_rad := deg_to_rad(spread_degrees)
	var yaw_off := randf_range(-spread_rad, spread_rad)
	var pitch_off := randf_range(-spread_rad, spread_rad)
	return forward.rotated(up, yaw_off).rotated(right, pitch_off).normalized()


func calculate_spread() -> float:
	if current_def["type"] == "special":
		return 0.0
	var def: Dictionary = current_def
	var is_ads := ads_amount > 0.5
	var base := 0.0
	var maximum := 0.0
	if player.crouching:
		base = def["spread_ads_crouch"] if is_ads else def["spread_crouch"]
		maximum = def["spread_ads_max_crouch"] if is_ads else def["spread_max_crouch"]
	else:
		base = def["spread_ads"] if is_ads else def["spread"]
		maximum = def["spread_ads_max"] if is_ads else def["spread_max"]

	var penalty := 0.0
	var speed := player.get_current_move_speed()
	if not player.is_on_floor():
		penalty = 10.0
	elif player.crouching and speed > 0.4:
		penalty = 0.8
	elif player.slow_walking and speed > 0.4:
		penalty = 3.0
	elif speed > 0.4:
		penalty = 6.0
	return clampf(base + penalty + spread_bonus, 0.0, maximum + penalty + 2.0)


func get_visual_spread() -> float:
	return calculate_spread()


func _add_recoil() -> void:
	var def: Dictionary = current_def
	var scale := 1.0
	if def["type"] == "sniper":
		scale = 1.35
	elif def["type"] == "pistol":
		scale = 0.75
	var vertical := 0.016 * scale + randf_range(0.0, 0.002 * scale)
	var horizontal := 0.0
	if spray_index >= 6:
		horizontal = randf_range(-0.014, 0.014) * (1.0 if randi() % 2 == 0 else -1.0) * scale
		vertical += 0.003 * scale
	recoil_target_pitch = minf(recoil_target_pitch + vertical, 0.55)
	recoil_target_yaw = clampf(recoil_target_yaw + horizontal, -0.3, 0.3)
	recovery_timer = RECOIL_RECOVERY_TIME


func _update_recoil(delta: float) -> void:
	if recovery_timer > 0.0:
		recovery_timer = maxf(0.0, recovery_timer - delta)
		var t := recovery_timer / RECOIL_RECOVERY_TIME
		recoil_pitch = recoil_target_pitch * t
		recoil_yaw = recoil_target_yaw * t
	else:
		recoil_pitch = 0.0
		recoil_yaw = 0.0
		recoil_target_pitch = 0.0
		recoil_target_yaw = 0.0


func _update_spray(delta: float) -> void:
	spread_bonus = maxf(0.0, spread_bonus - delta * 0.32)


func _update_lockon() -> void:
	if current_def["type"] != "special" or player == null or player.dead:
		_lock_target = null
		return
	var best: Node3D = null
	var best_distance := INF
	for target in get_tree().get_nodes_in_group("damageable"):
		var target_node: Node3D = target as Node3D
		if target_node == null or target_node == player:
			continue
		if not target_node.has_method("take_damage"):
			continue
		if target_node.get("dead") == true:
			continue
		var head: Vector3 = target_node.global_position + Vector3(0.0, 1.55, 0.0)
		var distance := camera.global_position.distance_to(head)
		if distance > current_def.get("range", 220.0):
			continue
		var query := PhysicsRayQueryParameters3D.create(camera.global_position, head, 0b1111)
		query.exclude = [player.get_rid()]
		var result := camera.get_world_3d().direct_space_state.intersect_ray(query)
		if result.is_empty() or result.collider == target_node:
			if distance < best_distance:
				best_distance = distance
				best = target_node
	_lock_target = best
	if best != null:
		var head: Vector3 = best.global_position + Vector3(0.0, 1.55, 0.0)
		player.set_locked_aim(head - camera.global_position)


func is_locked() -> bool:
	return _lock_target != null and current_def["type"] == "special"


func _update_ads(delta: float) -> void:
	if bolt_timer > 0.0 and _is_quickscope_mode() and current_weapon_id == "operator":
		ads_amount = maxf(0.0, ads_amount - delta / maxf(bolt_duration, 0.001))
	else:
		ads_amount = move_toward(ads_amount, ads_target, delta * 10.0)
	camera.fov = lerpf(BASE_FOV, BASE_FOV / current_def["ads_zoom"], ads_amount)


func _update_viewmodel(delta: float) -> void:
	if _viewmodel_nodes.is_empty():
		return
	var is_melee: bool = current_def["type"] == "melee"
	var scoped := current_weapon_id == "operator" and ads_amount > 0.5
	_viewmodel_root.visible = not scoped
	var base_x := 0.14 if is_melee else 0.22
	var base_y := -0.20 if is_melee else -0.22
	var base_z := -0.42 if is_melee else -0.45
	var ads_x := 0.0 if not is_melee else 0.14
	position.x = lerpf(base_x, ads_x, ads_amount)
	position.y = lerpf(base_y, -0.18, ads_amount)
	position.z = lerpf(base_z, -0.42, ads_amount)
	rotation.x = lerpf(0.0, -0.02, ads_amount)
	rotation.y = 0.0
	rotation.z = 0.0

	if reloading and not is_melee:
		var progress: float = 1.0 - reload_timer / current_def["reload_time"]
		var drop := 0.0
		if progress < 0.22:
			drop = progress / 0.22
		elif progress < 0.70:
			drop = 1.0
		elif progress < 0.90:
			drop = 1.0 - (progress - 0.70) / 0.20
		var smooth := drop * drop * (3.0 - 2.0 * drop)
		position.x += 0.045 * smooth
		position.y += -0.105 * smooth
		position.z += 0.145 * smooth
		rotation.x += 0.55 * smooth
		rotation.y += -0.42 * smooth
		rotation.z += 0.16 * smooth
		if _magazine_mesh != null:
			_magazine_mesh.visible = progress < 0.12 or progress > 0.78
		if progress > 0.78 and not _mag_done:
			_mag_done = true
			_play_sound(RELOAD_END_SOUND, -2.0, 1.0)

	if inspect_timer > 0.0:
		var p := 1.0 - inspect_timer / INSPECT_DURATION
		var wave := sin(p * PI)
		position.y += -0.10 + wave * (0.16 if is_melee else 0.12)
		position.z += wave * 0.12
		rotation.x += wave * (0.7 if is_melee else 0.4)
		if is_melee:
			rotation.y += p * TAU * 1.6
			rotation.z += sin(p * TAU) * 0.18
		else:
			rotation.y += sin(p * TAU) * 0.7
			rotation.z += sin(p * PI * 2.0) * 0.12

	if slash_timer > 0.0 and is_melee:
		var p: float = 1.0 - slash_timer / slash_duration
		var back := sin(p * PI)
		position.y += back * (0.10 if slash_mode == "stab" else 0.08)
		position.z += back * (0.16 if slash_mode == "stab" else 0.10)
		if slash_mode == "stab":
			rotation.x += back * 0.9
			rotation.z += back * -0.12
		elif slash_mode == "slash_a":
			rotation.y += sin(p * PI * 2.0) * 1.3
			rotation.x += back * 0.55
			rotation.z += back * 0.35
		else:
			rotation.y += sin(p * PI * 2.0) * -1.3
			rotation.x += back * 0.55
			rotation.z += back * -0.35
		if p > 0.78:
			var retract: float = (p - 0.78) / 0.22
			position.y += retract * -0.05
			position.z += retract * 0.06

	if bolt_timer > 0.0 and current_weapon_id == "operator":
		var p := 1.0 - bolt_timer / maxf(bolt_duration, 0.001)
		var bolt := sin(p * PI)
		position.y += bolt * 0.10
		position.z += bolt * 0.16
		rotation.x += bolt * 0.85
		rotation.y += sin(p * PI * 2.0) * 0.42
		rotation.z += sin(p * PI * 2.0) * 0.12

	if current_def["type"] == "special":
		var locked := _lock_target != null
		position.y += -0.02 + (0.02 if locked else 0.0)
		rotation.z += -0.06 + (0.08 if locked else 0.0)

	if player.get_current_move_speed() > 0.5 and player.is_on_floor() and not player.dead:
		var t := Time.get_ticks_msec() / 1000.0
		position.y += sin(t * 9.0) * 0.004
	position.y += player.get_vertical_anim_offset() * 0.35


func select_weapon_id(id: String, force := false) -> void:
	if not WEAPON_DEFS.has(id):
		return
	var settings := get_node_or_null("/root/Settings")
	if settings != null and settings.game_mode == "quickscope" and id != "operator":
		return
	if id == current_weapon_id and not force:
		return
	if _built and current_def.has("name"):
		_ammo[current_weapon_id] = {"magazine": magazine, "reserve": reserve}
	current_weapon_id = id
	current_def = WEAPON_DEFS[id]
	_load_ammo()
	_reset_weapon_state()
	_rebuild_viewmodel()
	weapon_selected.emit(id)


func start_inspect() -> void:
	if reloading or inspect_timer > 0.0 or slash_timer > 0.0 or bolt_timer > 0.0 or player == null or player.dead:
		return
	inspect_timer = INSPECT_DURATION
	inspect_started.emit()


func start_reload() -> void:
	if reloading or current_def["type"] == "melee":
		return
	var magazine_size: int = current_def["magazine_size"]
	if magazine == magazine_size or (reserve <= 0 and not _settings_bool("infinite_ammo")):
		return
	reloading = true
	reload_timer = current_def["reload_time"]
	_mag_done = false
	if _magazine_mesh != null:
		_magazine_mesh.visible = true
	_play_sound(RELOAD_START_SOUND, -2.0, 1.0)
	reload_started.emit()


func _finish_reload() -> void:
	var magazine_size: int = current_def["magazine_size"]
	var needed: int = magazine_size - magazine
	var taken: int = needed
	if not _settings_bool("infinite_ammo"):
		taken = mini(needed, reserve)
		reserve -= taken
	magazine += taken
	_ammo[current_weapon_id] = {"magazine": magazine, "reserve": reserve}
	reloading = false
	_mag_done = false
	if _magazine_mesh != null:
		_magazine_mesh.visible = true
	ammo_changed.emit(magazine, reserve)
	reload_finished.emit()


func get_reload_progress() -> float:
	if not reloading:
		return 0.0
	return clampf(1.0 - reload_timer / current_def["reload_time"], 0.0, 1.0)


func reset_ammo() -> void:
	for id in WEAPON_ORDER:
		_ammo[id] = {
			"magazine": WEAPON_DEFS[id]["magazine_size"],
			"reserve": WEAPON_DEFS[id]["reserve_size"]
		}
	_load_ammo()
	_reset_weapon_state()
	if _magazine_mesh != null:
		_magazine_mesh.visible = true
	ammo_changed.emit(magazine, reserve)


func _load_ammo() -> void:
	var ammo: Dictionary = _ammo[current_weapon_id]
	magazine = ammo["magazine"]
	reserve = ammo["reserve"]


func _reset_weapon_state() -> void:
	reloading = false
	reload_timer = 0.0
	fire_cooldown = 0.0
	spread_bonus = 0.0
	spray_index = 0
	recoil_target_pitch = 0.0
	recoil_target_yaw = 0.0
	recovery_timer = 0.0
	recoil_pitch = 0.0
	recoil_yaw = 0.0
	ads_amount = 0.0
	ads_target = 0.0
	inspect_timer = 0.0
	slash_timer = 0.0
	slash_mode = ""
	bolt_timer = 0.0
	bolt_duration = 1.0
	sniper_scope_on = false
	_rmb_was_down = false
	_lock_target = null
	_mag_done = false


func _rebuild_viewmodel() -> void:
	if _viewmodel_root == null:
		return
	for child in _viewmodel_root.get_children():
		child.free()
	_viewmodel_nodes.clear()
	_magazine_mesh = null
	match current_weapon_id:
		"vandal":
			_build_rifle(Color(0.78, 0.24, 0.20), 0.42, 0.24)
		"phantom":
			_build_rifle(Color(0.35, 0.62, 0.92), 0.46, 0.30)
		"operator":
			_build_operator()
		"sheriff":
			_build_sheriff()
		"knife":
			_build_knife()
		"lockon":
			_build_lockon()


func _build_rifle(accent: Color, body_length: float, magazine_length: float) -> void:
	_add_box(Vector3(0.07, 0.10, body_length), Color(0.12, 0.12, 0.14), Vector3(0.0, 0.0, -0.02))
	_add_box(Vector3(0.06, 0.08, 0.24), Color(0.20, 0.20, 0.23), Vector3(0.0, 0.01, -0.24))
	_add_box(Vector3(0.04, 0.04, 0.18), Color(0.10, 0.10, 0.12), Vector3(0.0, 0.035, -0.40))
	_magazine_mesh = _add_box(Vector3(0.05, magazine_length, 0.08), Color(0.16, 0.16, 0.19), Vector3(0.0, -magazine_length * 0.5, 0.10))
	_add_box(Vector3(0.05, 0.12, 0.08), Color(0.13, 0.13, 0.16), Vector3(0.0, -0.08, 0.18))
	_add_box(Vector3(0.05, 0.06, 0.05), accent, Vector3(0.0, 0.09, 0.02))
	_add_box(Vector3(0.035, 0.035, 0.06), accent, Vector3(0.0, 0.035, -0.34))


func _build_operator() -> void:
	_add_box(Vector3(0.07, 0.10, 0.62), Color(0.14, 0.14, 0.16), Vector3(0.0, 0.0, -0.04))
	_add_box(Vector3(0.05, 0.05, 0.34), Color(0.10, 0.10, 0.12), Vector3(0.0, 0.02, -0.36))
	_add_box(Vector3(0.06, 0.10, 0.10), Color(0.20, 0.20, 0.24), Vector3(0.0, 0.07, 0.04))
	_add_box(Vector3(0.05, 0.14, 0.06), Color(0.95, 0.76, 0.34), Vector3(0.0, -0.07, 0.16))
	_magazine_mesh = _add_box(Vector3(0.04, 0.18, 0.08), Color(0.15, 0.15, 0.18), Vector3(0.0, -0.11, 0.12))
	_add_box(Vector3(0.04, 0.04, 0.16), Color(0.95, 0.76, 0.34), Vector3(0.0, 0.045, -0.22))


func _build_sheriff() -> void:
	_add_box(Vector3(0.055, 0.055, 0.30), Color(0.14, 0.14, 0.16), Vector3(0.0, 0.02, -0.20))
	_add_box(Vector3(0.08, 0.11, 0.16), Color(0.16, 0.16, 0.18), Vector3(0.0, -0.02, 0.08))
	_add_cylinder(0.045, 0.10, Color(0.30, 0.28, 0.26), Vector3(0.0, -0.035, 0.02), Vector3(PI * 0.5, 0.0, 0.0))
	_add_box(Vector3(0.05, 0.10, 0.06), Color(0.68, 0.56, 0.42), Vector3(0.0, -0.08, 0.16))
	_add_box(Vector3(0.04, 0.03, 0.04), Color(0.68, 0.56, 0.42), Vector3(0.0, 0.075, 0.04))


func _build_knife() -> void:
	_add_box(Vector3(0.030, 0.045, 0.20), Color(0.86, 0.82, 0.78), Vector3(0.0, 0.0, -0.20))
	_add_box(Vector3(0.035, 0.050, 0.16), Color(0.12, 0.12, 0.14), Vector3(0.0, 0.0, 0.05))
	_add_box(Vector3(0.035, 0.045, 0.12), Color(0.16, 0.16, 0.18), Vector3(0.0, 0.065, -0.02))
	_add_box(Vector3(0.040, 0.030, 0.04), Color(0.88, 0.62, 0.24), Vector3(0.0, -0.03, -0.10))
	_add_box(Vector3(0.040, 0.030, 0.04), Color(0.88, 0.62, 0.24), Vector3(0.0, 0.025, 0.04))


func _build_lockon() -> void:
	_add_box(Vector3(0.07, 0.11, 0.46), Color(0.12, 0.12, 0.16), Vector3(0.0, 0.0, -0.03))
	_add_box(Vector3(0.05, 0.05, 0.24), Color(0.08, 0.08, 0.12), Vector3(0.0, 0.03, -0.34))
	_add_box(Vector3(0.05, 0.16, 0.08), Color(0.16, 0.16, 0.20), Vector3(0.0, -0.10, 0.12))
	_add_box(Vector3(0.05, 0.12, 0.08), Color(0.13, 0.13, 0.17), Vector3(0.0, -0.08, 0.20))
	_add_box(Vector3(0.05, 0.06, 0.05), Color(0.95, 0.35, 1.0), Vector3(0.0, 0.10, 0.02))
	_add_box(Vector3(0.035, 0.035, 0.08), Color(0.95, 0.35, 1.0), Vector3(0.0, 0.04, -0.36))
	_add_box(Vector3(0.04, 0.04, 0.06), Color(0.35, 0.9, 1.0), Vector3(0.0, 0.02, -0.10))


func _play_sound(stream: AudioStream, volume: float, pitch: float) -> void:
	if _sfx == null:
		return
	_sfx.stream = stream
	_sfx.volume_db = volume
	_sfx.pitch_scale = pitch
	_sfx.play()


func _add_box(size: Vector3, color: Color, offset: Vector3) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.5
	mat.roughness = 0.45
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = offset
	_viewmodel_root.add_child(mi)
	_viewmodel_nodes.append(mi)
	return mi


func _add_cylinder(radius: float, height: float, color: Color, offset: Vector3, rotation: Vector3) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.6
	mat.roughness = 0.35
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = offset
	mi.rotation = rotation
	_viewmodel_root.add_child(mi)
	_viewmodel_nodes.append(mi)
	return mi


func _settings_bool(property_name: String) -> bool:
	var settings := get_node_or_null("/root/Settings")
	return settings != null and settings.get(property_name) == true


func _is_quickscope_mode() -> bool:
	var settings := get_node_or_null("/root/Settings")
	return settings != null and settings.game_mode == "quickscope"


func _has_infinite_magazine() -> bool:
	return _is_quickscope_mode() or _settings_bool("infinite_magazine")
