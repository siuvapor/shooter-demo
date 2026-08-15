class_name Player
extends CharacterBody3D


signal health_changed(current: int, maximum: int)
signal died
signal respawned
signal hit_marker(zone: String)

const MAX_HEALTH := 150
const WALK_SPEED := 5.4
const SLOW_WALK_SPEED := 4.5
const CROUCH_SPEED := 4.1
const ADS_SPEED := 4.104
const JUMP_VELOCITY := 7.6
const GRAVITY := 24.0
const DEFAULT_MOUSE_SENSITIVITY := 0.0018
const STAND_HEIGHT := 1.8
const CROUCH_HEIGHT := 1.1
const STAND_EYE := 1.62
const CROUCH_EYE := 0.98
const HEAD_ZONE_HEIGHT := 1.36
const LEG_ZONE_HEIGHT := 0.58

const HURT_SOUND := preload("res://assets/audio/hurt.wav")
const FOOTSTEP_SOUND := preload("res://assets/audio/footstep.wav")

var camera: Camera3D
var weapon: Weapon
var collision_shape: CollisionShape3D
var player_sfx: AudioStreamPlayer
var mouse_sensitivity := DEFAULT_MOUSE_SENSITIVITY

var health := MAX_HEALTH
var dead := false
var crouching := false
var slow_walking := false
var ads := false
var base_pitch := 0.0
var base_yaw := 0.0
var _spawn_position := Vector3.ZERO
var _spawn_yaw := 0.0
var _footstep_timer := 0.0
var _downed_time := 0.0
var _jump_anim := 0.0
var _land_anim := 0.0
var _was_on_floor := true


func _ready() -> void:
	_build_body()
	floor_max_angle = deg_to_rad(50.0)
	set_collision_layer_value(2, true)
	set_collision_mask_value(1, true)
	set_collision_mask_value(2, true)
	set_collision_mask_value(4, true)
	weapon.setup(self, camera)
	var settings := get_node_or_null("/root/Settings")
	if settings != null:
		mouse_sensitivity = settings.mouse_sensitivity
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_spawn_position = global_position
	_spawn_yaw = rotation.y
	health_changed.emit(health, MAX_HEALTH)


func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _build_body() -> void:
	collision_shape = CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = STAND_HEIGHT
	collision_shape.shape = capsule
	collision_shape.position = Vector3(0.0, STAND_HEIGHT * 0.5, 0.0)
	add_child(collision_shape)

	player_sfx = AudioStreamPlayer.new()
	player_sfx.name = "PlayerSfx"
	player_sfx.max_polyphony = 4
	add_child(player_sfx)

	camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.fov = 70.0
	camera.position = Vector3(0.0, STAND_EYE, 0.0)
	camera.current = true
	add_child(camera)

	weapon = Weapon.new()
	weapon.name = "Weapon"
	weapon.position = Vector3(0.22, -0.22, -0.45)
	camera.add_child(weapon)


func _input(event: InputEvent) -> void:
	if weapon != null and weapon.current_weapon_id == "lockon":
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		base_yaw -= event.relative.x * mouse_sensitivity
		base_pitch -= event.relative.y * mouse_sensitivity
		base_pitch = clampf(base_pitch, -1.55, 1.55)
		rotation.y = base_yaw


func _process(_delta: float) -> void:
	if camera != null and weapon != null:
		if dead:
			_update_downed(_delta)
		else:
			camera.rotation.x = base_pitch + weapon.recoil_pitch
			camera.rotation.y = weapon.recoil_yaw
			_update_vertical_anim(_delta)


func _physics_process(delta: float) -> void:
	_update_pose()
	var was_on_floor := is_on_floor()
	if dead:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	slow_walking = Input.is_key_pressed(KEY_SHIFT)
	ads = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and not dead
	var input_vector := Vector2(
		float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
		float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
	)
	if input_vector.length_squared() > 1.0:
		input_vector = input_vector.normalized()
	var direction := (transform.basis * Vector3(input_vector.x, 0.0, input_vector.y)).normalized()
	var speed := WALK_SPEED
	if crouching:
		speed = CROUCH_SPEED
	elif slow_walking:
		speed = SLOW_WALK_SPEED
	if ads and is_on_floor():
		speed = minf(speed, ADS_SPEED)

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	elif Input.is_physical_key_pressed(KEY_SPACE):
		velocity.y = JUMP_VELOCITY
		_jump_anim = 0.34
	else:
		velocity.y = 0.0
	move_and_slide()
	if is_on_floor() and not was_on_floor and velocity.y <= 0.0:
		_land_anim = 0.28
	_was_on_floor = is_on_floor()
	_update_footsteps(delta)


func _update_pose() -> void:
	var want_crouch := Input.is_physical_key_pressed(KEY_CTRL) and not dead
	if want_crouch == crouching:
		return
	crouching = want_crouch
	var height := CROUCH_HEIGHT if crouching else STAND_HEIGHT
	var eye := CROUCH_EYE if crouching else STAND_EYE
	var capsule := collision_shape.shape as CapsuleShape3D
	capsule.height = height
	collision_shape.position.y = height * 0.5
	camera.position.y = eye


func get_current_move_speed() -> float:
	return Vector2(velocity.x, velocity.z).length()


func resolve_hit_zone(hit_point: Vector3) -> String:
	var relative_y := hit_point.y - global_position.y
	if relative_y >= HEAD_ZONE_HEIGHT:
		return "head"
	if relative_y >= LEG_ZONE_HEIGHT:
		return "body"
	return "legs"


func take_damage(amount: int, zone: String, hit_point: Vector3, hit_normal: Vector3, _source: Node3D) -> void:
	if dead:
		return
	_play_sound(HURT_SOUND, -4.0, randf_range(0.9, 1.1))
	health = maxi(0, health - amount)
	health_changed.emit(health, MAX_HEALTH)
	if health == 0:
		dead = true
		_downed_time = 0.0
		weapon.visible = false
		died.emit()


func respawn_at(pos: Vector3, yaw: float) -> void:
	global_position = pos
	rotation = Vector3(0.0, yaw, 0.0)
	base_yaw = yaw
	base_pitch = 0.0
	velocity = Vector3.ZERO
	health = MAX_HEALTH
	dead = false
	crouching = false
	_downed_time = 0.0
	var capsule := collision_shape.shape as CapsuleShape3D
	capsule.height = STAND_HEIGHT
	collision_shape.position.y = STAND_HEIGHT * 0.5
	camera.position.y = STAND_EYE
	camera.rotation.z = 0.0
	weapon.visible = true
	_footstep_timer = 0.0
	_jump_anim = 0.0
	_land_anim = 0.0
	_was_on_floor = true
	weapon.reset_ammo()
	health_changed.emit(health, MAX_HEALTH)
	respawned.emit()


func _update_downed(delta: float) -> void:
	_downed_time += delta
	var t := clampf(_downed_time / 0.8, 0.0, 1.0)
	var eased := 1.0 - pow(1.0 - t, 3.0)
	camera.position.y = lerpf(STAND_EYE, 0.25, eased)
	camera.rotation.x = base_pitch - 1.35 * eased
	camera.rotation.y = weapon.recoil_yaw if weapon != null else 0.0
	camera.rotation.z = 0.08 * eased


func _update_vertical_anim(delta: float) -> void:
	var offset := 0.0
	if _jump_anim > 0.0:
		_jump_anim = maxf(0.0, _jump_anim - delta)
		var t := 1.0 - _jump_anim / 0.34
		offset += sin(t * PI) * 0.14
	if _land_anim > 0.0:
		_land_anim = maxf(0.0, _land_anim - delta)
		var t := 1.0 - _land_anim / 0.28
		offset -= sin(t * PI) * 0.08
	camera.position.y = (CROUCH_EYE if crouching else STAND_EYE) + offset


func get_vertical_anim_offset() -> float:
	return camera.position.y - (CROUCH_EYE if crouching else STAND_EYE)


func set_locked_aim(direction: Vector3) -> void:
	var flat := Vector2(direction.x, direction.z)
	if flat.length() < 0.001:
		return
	base_yaw = atan2(-direction.x, -direction.z)
	base_pitch = clampf(atan2(direction.y, flat.length()), -1.55, 1.55)
	rotation.y = base_yaw


func _update_footsteps(delta: float) -> void:
	if dead or not is_on_floor():
		_footstep_timer = 0.15
		return
	var speed := get_current_move_speed()
	if speed < 0.5:
		_footstep_timer = 0.15
		return
	var interval := 0.32
	var volume := -5.0
	if crouching:
		interval = 0.46
		volume = -10.0
	elif slow_walking:
		interval = 0.54
		volume = -15.0
	_footstep_timer -= delta
	if _footstep_timer <= 0.0:
		_footstep_timer = interval
		_play_sound(FOOTSTEP_SOUND, volume, randf_range(0.92, 1.08))


func _play_sound(stream: AudioStream, volume: float, pitch: float) -> void:
	if player_sfx == null:
		return
	player_sfx.stream = stream
	player_sfx.volume_db = volume
	player_sfx.pitch_scale = pitch
	player_sfx.play()
