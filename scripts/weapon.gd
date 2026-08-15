class_name Weapon
extends Node3D


signal ammo_changed(magazine: int, reserve: int)
signal fired
signal reload_started
signal reload_finished

const FIRE_RATE := 9.75
const ADS_FIRE_RATE := 8.775
const MAGAZINE_SIZE := 25
const RESERVE_SIZE := 50
const RELOAD_TIME := 2.5
const ADS_ZOOM := 1.25
const BASE_FOV := 70.0
const RANGE := 300.0

const DAMAGE_HEAD := 160
const DAMAGE_BODY := 40
const DAMAGE_LEG := 34

const SPREAD_STANDING := 0.25
const SPREAD_CROUCHED := 0.21
const SPREAD_MAX_STANDING := 1.0
const SPREAD_MAX_CROUCHED := 0.85
const SPREAD_ADS := 0.157
const SPREAD_ADS_CROUCHED := 0.13
const SPREAD_ADS_MAX := 1.02
const SPREAD_ADS_MAX_CROUCHED := 0.87
const MOVE_PENALTY_WALK := 3.0
const MOVE_PENALTY_RUN := 6.0
const MOVE_PENALTY_AIR := 10.0
const MOVE_PENALTY_CROUCH := 0.8
const RECOIL_RECOVERY_TIME := 0.375

const GUNSHOT_SOUND := preload("res://assets/audio/gunshot.wav")
const RELOAD_START_SOUND := preload("res://assets/audio/reload_start.wav")
const RELOAD_END_SOUND := preload("res://assets/audio/reload_end.wav")
const HIT_SOUND := preload("res://assets/audio/hitmarker.wav")
const HEADSHOT_SOUND := preload("res://assets/audio/headshot.wav")

var player: Player
var camera: Camera3D
var magazine := MAGAZINE_SIZE
var reserve := RESERVE_SIZE
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
var _sfx: AudioStreamPlayer
var _magazine_mesh: MeshInstance3D
var _mag_done := false
var _viewmodel_nodes: Array[Node3D] = []
var _built := false


func setup(owner_player: Player, cam: Camera3D) -> void:
	player = owner_player
	camera = cam
	if not _built:
		build_viewmodel()


func _process(delta: float) -> void:
	if player == null or camera == null:
		return
	_update_ads(delta)
	_update_recoil(delta)
	_update_spray(delta)
	_update_viewmodel(delta)
	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	if reloading:
		reload_timer -= delta
		if reload_timer <= 0.0:
			_finish_reload()
	if player.dead:
		return
	ads_target = 1.0 if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) else 0.0
	if Input.is_physical_key_pressed(KEY_R):
		start_reload()
	if magazine == 0 and not reloading:
		start_reload()
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and fire_cooldown <= 0.0 and not reloading and magazine > 0:
		fire()


func fire() -> void:
	var is_ads := ads_amount > 0.5
	fire_cooldown = 1.0 / (ADS_FIRE_RATE if is_ads else FIRE_RATE)
	magazine -= 1
	ammo_changed.emit(magazine, reserve)

	var from := camera.global_position
	var direction := _shoot_direction(calculate_spread())
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


func _resolve_hit(result: Dictionary) -> void:
	var collider: Node = result.collider
	if collider == null or not collider.is_in_group("damageable"):
		Fx.spawn_impact(get_tree().current_scene, result.position, result.normal)
		return
	var zone := "body"
	if collider.has_method("resolve_hit_zone"):
		zone = collider.resolve_hit_zone(result.position)
	var damage := DAMAGE_HEAD if zone == "head" else DAMAGE_BODY if zone == "body" else DAMAGE_LEG
	if collider.has_method("take_damage"):
		collider.take_damage(damage, zone, result.position, result.normal, player)
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
	var is_ads := ads_amount > 0.5
	var base := 0.0
	var maximum := 0.0
	if player.crouching:
		base = SPREAD_ADS_CROUCHED if is_ads else SPREAD_CROUCHED
		maximum = SPREAD_ADS_MAX_CROUCHED if is_ads else SPREAD_MAX_CROUCHED
	else:
		base = SPREAD_ADS if is_ads else SPREAD_STANDING
		maximum = SPREAD_ADS_MAX if is_ads else SPREAD_MAX_STANDING

	var penalty := 0.0
	var speed := player.get_current_move_speed()
	if not player.is_on_floor():
		penalty = MOVE_PENALTY_AIR
	elif player.crouching and speed > 0.4:
		penalty = MOVE_PENALTY_CROUCH
	elif player.slow_walking and speed > 0.4:
		penalty = MOVE_PENALTY_WALK
	elif speed > 0.4:
		penalty = MOVE_PENALTY_RUN
	return clampf(base + penalty + spread_bonus, 0.0, maximum + penalty + 2.0)


func get_visual_spread() -> float:
	return calculate_spread()


func _add_recoil() -> void:
	var vertical := 0.016 + randf_range(0.0, 0.002)
	var horizontal := 0.0
	if spray_index >= 6:
		horizontal = randf_range(-0.014, 0.014) * (1.0 if randi() % 2 == 0 else -1.0)
		vertical += 0.003
	recoil_target_pitch = minf(recoil_target_pitch + vertical, 0.5)
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


func _update_ads(delta: float) -> void:
	ads_amount = move_toward(ads_amount, ads_target, delta * 10.0)
	camera.fov = lerpf(BASE_FOV, BASE_FOV / ADS_ZOOM, ads_amount)


func _update_viewmodel(delta: float) -> void:
	if _viewmodel_nodes.is_empty():
		return
	position.x = lerpf(0.22, 0.0, ads_amount)
	position.y = lerpf(-0.22, -0.18, ads_amount)
	position.z = lerpf(-0.45, -0.42, ads_amount)
	rotation.x = lerpf(0.0, -0.02, ads_amount)
	if reloading:
		var progress := 1.0 - reload_timer / RELOAD_TIME
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
	if player.get_current_move_speed() > 0.5 and player.is_on_floor() and not player.dead:
		var t := Time.get_ticks_msec() / 1000.0
		position.y += sin(t * 9.0) * 0.004


func start_reload() -> void:
	if reloading or magazine == MAGAZINE_SIZE or reserve <= 0:
		return
	reloading = true
	reload_timer = RELOAD_TIME
	_mag_done = false
	if _magazine_mesh != null:
		_magazine_mesh.visible = true
	_play_sound(RELOAD_START_SOUND, -2.0, 1.0)
	reload_started.emit()


func _finish_reload() -> void:
	var needed := MAGAZINE_SIZE - magazine
	var taken := mini(needed, reserve)
	magazine += taken
	reserve -= taken
	reloading = false
	_mag_done = false
	if _magazine_mesh != null:
		_magazine_mesh.visible = true
	ammo_changed.emit(magazine, reserve)
	reload_finished.emit()


func get_reload_progress() -> float:
	if not reloading:
		return 0.0
	return clampf(1.0 - reload_timer / RELOAD_TIME, 0.0, 1.0)


func reset_ammo() -> void:
	magazine = MAGAZINE_SIZE
	reserve = RESERVE_SIZE
	reloading = false
	reload_timer = 0.0
	_mag_done = false
	spread_bonus = 0.0
	spray_index = 0
	recoil_target_pitch = 0.0
	recoil_target_yaw = 0.0
	recovery_timer = 0.0
	recoil_pitch = 0.0
	recoil_yaw = 0.0
	if _magazine_mesh != null:
		_magazine_mesh.visible = true
	ammo_changed.emit(magazine, reserve)


func build_viewmodel() -> void:
	_built = true
	_sfx = AudioStreamPlayer.new()
	_sfx.name = "Sfx"
	_sfx.max_polyphony = 4
	add_child(_sfx)
	_add_box(Vector3(0.07, 0.10, 0.42), Color(0.12, 0.12, 0.14), Vector3(0.0, 0.0, -0.02))
	_add_box(Vector3(0.06, 0.08, 0.24), Color(0.20, 0.20, 0.23), Vector3(0.0, 0.01, -0.24))
	_add_box(Vector3(0.04, 0.04, 0.18), Color(0.10, 0.10, 0.12), Vector3(0.0, 0.035, -0.40))
	_magazine_mesh = _add_box(Vector3(0.05, 0.16, 0.08), Color(0.16, 0.16, 0.19), Vector3(0.0, -0.10, 0.10))
	_add_box(Vector3(0.05, 0.12, 0.08), Color(0.13, 0.13, 0.16), Vector3(0.0, -0.08, 0.18))
	_add_box(Vector3(0.05, 0.06, 0.05), Color(0.78, 0.24, 0.20), Vector3(0.0, 0.09, 0.02))
	_add_box(Vector3(0.035, 0.035, 0.06), Color(0.78, 0.24, 0.20), Vector3(0.0, 0.035, -0.34))


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
	add_child(mi)
	_viewmodel_nodes.append(mi)
	return mi
