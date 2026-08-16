class_name DuelBot
extends CharacterBody3D


signal health_changed(current: int, maximum: int)
signal died
signal respawned
signal fired
signal shield_changed(active: bool)

const MAX_HEALTH := 150
const SPAWN_SHIELD_TIME := 1.0
const WALK_SPEED := 5.4
const CROUCH_SPEED := 4.1
const GRAVITY := 22.0
const FIRE_RATE := 9.75
const DAMAGE_HEAD := 160
const DAMAGE_BODY := 40
const DAMAGE_LEG := 34
const AIM_ERROR := 0.035
const HEAD_ZONE_HEIGHT := 1.36
const LEG_ZONE_HEIGHT := 0.58
const QUICKSCOPE_SPEED_MULTIPLIER := 5.0

const GUNSHOT_SOUND := preload("res://assets/audio/gunshot.wav")

var player: Player
var health := MAX_HEALTH
var dead := false
var eye: Marker3D
var health_label: Label3D
var body_root: Node3D
var collision_shape: CollisionShape3D
var _waypoints: Array[Vector3] = []
var _move_target := Vector3.ZERO
var _attack_timer := 0.0
var _burst_left := 0
var _shot_cooldown := 0.0
var _spawn_position := Vector3.ZERO
var _spawn_yaw := 0.0
var _torso_material: StandardMaterial3D
var _gun_sfx: AudioStreamPlayer3D
var _downed_time := 0.0
var speed_multiplier := 1.0
var aim_error := AIM_ERROR
var shield_active := false
var shield_timer := 0.0
var shield_mesh: MeshInstance3D
var quickscope_mode := false
var _quickscope_action := 1
var _quickscope_timer := 0.0
var _quickscope_target := Vector3.ZERO
var _quickscope_side := 1.0
var _jump_peek_side := 1.0
var _peek_center_z := 0.0
var _peek_target_z := 0.0
var _rifle_mesh: MeshInstance3D


func _ready() -> void:
	floor_max_angle = deg_to_rad(50.0)
	set_collision_layer_value(4, true)
	set_collision_mask_value(1, true)
	set_collision_mask_value(2, true)
	set_collision_mask_value(4, true)
	_build_visuals()
	_spawn_position = global_position
	_spawn_yaw = rotation.y
	shield_active = true
	shield_timer = SPAWN_SHIELD_TIME
	_update_shield_visual()


func _build_visuals() -> void:
	collision_shape = CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.8
	collision_shape.shape = capsule
	collision_shape.position = Vector3(0.0, 0.9, 0.0)
	add_child(collision_shape)

	_gun_sfx = AudioStreamPlayer3D.new()
	_gun_sfx.name = "GunSfx"
	_gun_sfx.max_db = 3.0
	_gun_sfx.unit_size = 10.0
	add_child(_gun_sfx)

	eye = Marker3D.new()
	eye.name = "Eye"
	eye.position = Vector3(0.0, 1.55, 0.0)
	add_child(eye)

	body_root = Node3D.new()
	body_root.name = "Body"
	add_child(body_root)
	_add_box(body_root, Vector3(0.22, 0.5, 0.22), Color(0.12, 0.13, 0.16), Vector3(-0.11, 0.25, 0.0))
	_add_box(body_root, Vector3(0.22, 0.5, 0.22), Color(0.12, 0.13, 0.16), Vector3(0.11, 0.25, 0.0))
	var torso := _add_box(body_root, Vector3(0.52, 0.7, 0.32), Color(0.80, 0.20, 0.20), Vector3(0.0, 0.92, 0.0))
	_torso_material = torso.material_override as StandardMaterial3D
	_add_box(body_root, Vector3(0.16, 0.5, 0.20), Color(0.16, 0.16, 0.20), Vector3(-0.38, 0.90, 0.0))
	_add_box(body_root, Vector3(0.16, 0.5, 0.20), Color(0.16, 0.16, 0.20), Vector3(0.38, 0.90, 0.0))
	_rifle_mesh = _add_box(body_root, Vector3(0.12, 0.16, 0.72), Color(0.10, 0.10, 0.12), Vector3(0.26, 0.78, -0.38))
	_add_box(body_root, Vector3(0.32, 0.32, 0.32), Color(0.94, 0.75, 0.55), Vector3(0.0, 1.58, 0.0))
	_add_box(body_root, Vector3(0.34, 0.12, 0.34), Color(0.80, 0.20, 0.20), Vector3(0.0, 1.72, 0.0))

	health_label = Label3D.new()
	health_label.name = "HealthLabel"
	health_label.text = str(MAX_HEALTH)
	health_label.position = Vector3(0.0, 2.15, 0.0)
	health_label.font_size = 64
	health_label.pixel_size = 0.01
	health_label.outline_size = 12
	health_label.modulate = Color(1.0, 1.0, 1.0)
	add_child(health_label)

	shield_mesh = MeshInstance3D.new()
	shield_mesh.name = "ShieldMesh"
	var sphere := SphereMesh.new()
	sphere.radius = 0.78
	sphere.height = 1.9
	var shield_mat := StandardMaterial3D.new()
	shield_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shield_mat.albedo_color = Color(0.35, 0.75, 1.0, 0.26)
	shield_mat.emission_enabled = true
	shield_mat.emission = Color(0.35, 0.75, 1.0)
	shield_mat.emission_energy_multiplier = 0.7
	shield_mesh.mesh = sphere
	shield_mesh.material_override = shield_mat
	shield_mesh.position = Vector3(0.0, 0.9, 0.0)
	add_child(shield_mesh)


func set_player(target: Player) -> void:
	player = target


func set_waypoints(points: Array[Vector3]) -> void:
	_waypoints = points
	if not _waypoints.is_empty():
		_move_target = _waypoints[0]


func set_spawn_point(pos: Vector3, yaw: float) -> void:
	_spawn_position = pos
	_spawn_yaw = yaw


func set_quickscope_mode(enabled: bool) -> void:
	quickscope_mode = enabled
	speed_multiplier = QUICKSCOPE_SPEED_MULTIPLIER
	if _rifle_mesh != null:
		_rifle_mesh.visible = false
	shield_active = false
	shield_timer = 0.0
	_update_shield_visual()
	_quickscope_timer = 0.1
	_choose_quickscope_action()


func _physics_process(delta: float) -> void:
	if player == null:
		return
	if dead:
		_downed_time += delta
		var t := clampf(_downed_time / 0.8, 0.0, 1.0)
		var eased := 1.0 - pow(1.0 - t, 3.0)
		body_root.rotation.x = -PI * 0.5 * eased
		body_root.position.y = 0.06 * eased
		velocity = Vector3.ZERO
		move_and_slide()
		return
	_update_shield(delta)
	if quickscope_mode:
		_update_quickscope_action(delta)
		return
	_attack_timer -= delta
	_shot_cooldown = maxf(0.0, _shot_cooldown - delta)
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0
	_face_player(delta)
	_patrol()
	move_and_slide()
	if _can_see_player():
		_try_attack()


func _update_quickscope_action(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0
	_quickscope_timer -= delta
	if _quickscope_timer <= 0.0:
		_choose_quickscope_action()
	match _quickscope_action:
		1:
			_old_lady_walk(delta)
		2:
			_jump_peek(delta)
		3:
			_quick_pass(delta)
	move_and_slide()


func _choose_quickscope_action() -> void:
	var roll := randi_range(1, 100)
	if roll <= 22:
		_quickscope_action = 1
	elif roll <= 64:
		_quickscope_action = 2
	else:
		_quickscope_action = 3
	_quickscope_timer = randf_range(1.5, 2.2)
	_quickscope_side = 1.0 if randi() % 2 == 0 else -1.0
	if _quickscope_action == 1:
		_quickscope_target = Vector3(randf_range(4.0, 16.0), 0.0, randf_range(-6.0, 6.0))
	elif _quickscope_action == 2:
		_jump_peek_side = 1.0 if randi() % 2 == 0 else -1.0
		_peek_center_z = clampf(global_position.z, -1.4, 1.4)
		_peek_target_z = _peek_center_z + _jump_peek_side * 1.1


func _old_lady_walk(delta: float) -> void:
	rotation.y += delta * 5.5 * _quickscope_side
	var t := Time.get_ticks_msec() / 1000.0
	body_root.rotation.x = 0.34 + sin(t * 5.0) * 0.14
	body_root.rotation.z = sin(t * 4.0) * 0.30
	var to_target := _quickscope_target - global_position
	to_target.y = 0.0
	if to_target.length() < 0.6:
		_quickscope_side *= -1.0
		_quickscope_target = Vector3(randf_range(4.0, 16.0), 0.0, randf_range(-6.0, 6.0))
		to_target = _quickscope_target - global_position
	velocity = to_target.normalized() * WALK_SPEED


func _jump_peek(delta: float) -> void:
	body_root.rotation.x = lerpf(body_root.rotation.x, 0.0, 0.1)
	body_root.rotation.z = lerpf(body_root.rotation.z, 0.0, 0.1)
	_face_player(delta)
	if is_on_floor():
		if absf(global_position.z - _peek_target_z) < 0.3:
			_jump_peek_side *= -1.0
			_peek_target_z = _peek_center_z + _jump_peek_side * 1.1
		velocity.y = 7.6
		velocity.x = 0.0
		velocity.z = clampf((_peek_target_z - global_position.z) * 3.6, -5.6, 5.6)
	else:
		velocity.x = 0.0
		velocity.z = clampf((_peek_target_z - global_position.z) * 3.6, -5.6, 5.6)


func _quick_pass(delta: float) -> void:
	body_root.rotation.x = 0.0
	body_root.rotation.z = lerpf(body_root.rotation.z, 0.0, 0.1)
	_face_player(delta)
	var target := Vector3(randf_range(4.0, 16.0), 0.0, 6.0 * _quickscope_side)
	var to_target := target - global_position
	to_target.y = 0.0
	if to_target.length() < 1.0:
		_choose_quickscope_action()
		return
	velocity = to_target.normalized() * (WALK_SPEED * speed_multiplier * 1.45)


func _face_player(delta: float) -> void:
	if player == null:
		return
	var to_player := player.global_position - global_position
	to_player.y = 0.0
	if to_player.length() < 0.01:
		return
	var target_yaw := atan2(-to_player.x, -to_player.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, minf(1.0, 8.0 * delta))


func _patrol() -> void:
	if _waypoints.is_empty():
		velocity.x = 0.0
		velocity.z = 0.0
		return
	var to_target := _move_target - global_position
	to_target.y = 0.0
	if to_target.length() < 0.6:
		_move_target = _waypoints[randi() % _waypoints.size()]
		return
	var speed := WALK_SPEED
	if _can_see_player():
		speed = CROUCH_SPEED
	speed *= speed_multiplier
	var direction := to_target.normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed


func _can_see_player() -> bool:
	if player == null or player.dead:
		return false
	var from := eye.global_position
	var to := player.camera.global_position
	var query := PhysicsRayQueryParameters3D.create(from, to, 0b1111)
	query.exclude = [get_rid()]
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	return result.is_empty() or result.collider == player


func _try_attack() -> void:
	if quickscope_mode:
		return
	if _burst_left <= 0 and _attack_timer <= 0.0:
		_burst_left = randi_range(3, 6)
		_attack_timer = randf_range(0.75, 1.25)
	if _burst_left > 0 and _shot_cooldown <= 0.0:
		_shoot()
		_burst_left -= 1
		_shot_cooldown = 1.0 / FIRE_RATE


func _shoot() -> void:
	var from := eye.global_position
	var direction := _aim_direction()
	var to := from + direction * 300.0
	var query := PhysicsRayQueryParameters3D.create(from, to, 0b1111)
	query.exclude = [get_rid()]
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	var end := to
	if result:
		end = result.position
		var collider: Node = result.collider
		if collider == player:
			var zone := player.resolve_hit_zone(result.position)
			var damage := DAMAGE_HEAD if zone == "head" else DAMAGE_BODY if zone == "body" else DAMAGE_LEG
			player.take_damage(damage, zone, result.position, result.normal, self)
	var world := get_tree().current_scene
	Fx.spawn_tracer(world, from, end, Color(1.0, 0.28, 0.2))
	Fx.spawn_muzzle_flash(world, from + direction * 0.45, Color(1.0, 0.32, 0.2))
	_gun_sfx.stream = GUNSHOT_SOUND
	_gun_sfx.volume_db = -8.0
	_gun_sfx.pitch_scale = randf_range(0.95, 1.05)
	_gun_sfx.play()
	fired.emit()


func _aim_direction() -> Vector3:
	var target := player.camera.global_position
	var to_target := target - eye.global_position
	var distance := to_target.length()
	var error := aim_error + maxf(0.0, distance - 8.0) * 0.0025
	if player.crouching:
		error += 0.012
	var forward := to_target.normalized()
	var right := forward.cross(Vector3.UP)
	if right.length() < 0.001:
		right = Vector3.RIGHT
	right = right.normalized()
	var up := right.cross(forward).normalized()
	var yaw_off := randf_range(-error, error)
	var pitch_off := randf_range(-error, error)
	return forward.rotated(up, yaw_off).rotated(right, pitch_off).normalized()


func take_damage(amount: int, zone: String, hit_point: Vector3, hit_normal: Vector3, _source: Node3D) -> void:
	if dead or shield_active:
		return
	health = maxi(0, health - amount)
	health_label.text = str(health)
	health_changed.emit(health, MAX_HEALTH)
	_flash_damage()
	if health == 0:
		dead = true
		_downed_time = 0.0
		health_label.text = "DEAD"
		died.emit()


func resolve_hit_zone(hit_point: Vector3) -> String:
	var relative_y := hit_point.y - global_position.y
	if relative_y >= HEAD_ZONE_HEIGHT:
		return "head"
	if relative_y >= LEG_ZONE_HEIGHT:
		return "body"
	return "legs"


func respawn() -> void:
	health = MAX_HEALTH
	dead = false
	global_position = _spawn_position
	rotation = Vector3(0.0, _spawn_yaw, 0.0)
	velocity = Vector3.ZERO
	_downed_time = 0.0
	body_root.rotation.x = 0.0
	body_root.position.y = 0.0
	if quickscope_mode:
		shield_active = false
		shield_timer = 0.0
	else:
		shield_active = true
		shield_timer = SPAWN_SHIELD_TIME
	_update_shield_visual()
	if not _waypoints.is_empty():
		_move_target = _waypoints[randi() % _waypoints.size()]
	_burst_left = 0
	_attack_timer = 0.0
	_shot_cooldown = 0.0
	if quickscope_mode:
		_choose_quickscope_action()
	health_changed.emit(health, MAX_HEALTH)
	respawned.emit()


func _update_shield(delta: float) -> void:
	if not shield_active or dead:
		return
	shield_timer = maxf(0.0, shield_timer - delta)
	if shield_timer <= 0.0:
		shield_active = false
		_update_shield_visual()
		shield_changed.emit(false)


func _update_shield_visual() -> void:
	if shield_mesh != null:
		shield_mesh.visible = shield_active
	if health_label != null:
		health_label.text = "SHIELD" if shield_active else str(health)


func _flash_damage() -> void:
	if _torso_material == null:
		return
	var original := _torso_material.albedo_color
	_torso_material.albedo_color = Color(1.0, 0.9, 0.9)
	var tween := create_tween()
	tween.tween_property(_torso_material, "albedo_color", original, 0.12)


func _add_box(parent: Node3D, size: Vector3, color: Color, offset: Vector3) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.65
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = offset
	parent.add_child(mi)
	return mi
