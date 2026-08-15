class_name ZombieEnemy
extends CharacterBody3D


signal health_changed(current: int, maximum: int)
signal died
signal attacked

const MAX_HEALTH := 120
const BASE_SPEED := 6.2
const MELEE_DAMAGE := 35
const ATTACK_RANGE := 2.0
const MAX_HEIGHT_DIFF := 0.9
const ATTACK_COOLDOWN := 1.1
const ATTACK_ANIM_TIME := 0.5
const ATTACK_IMPACT_FRACTION := 0.46
const GRAVITY := 24.0
const HEAD_ZONE_HEIGHT := 1.36
const LEG_ZONE_HEIGHT := 0.58

const SLASH_SOUND := preload("res://assets/audio/slash.wav")

var player: Player
var health := MAX_HEALTH
var dead := false
var body_root: Node3D
var collision_shape: CollisionShape3D
var _right_arm_pivot: Node3D
var _left_arm_pivot: Node3D
var _knife_mesh: MeshInstance3D
var _zombie_sfx: AudioStreamPlayer3D
var _attack_timer := 0.0
var _attack_anim_timer := 0.0
var _attack_impact_done := true
var _downed_time := 0.0
var _alive_time := 0.0
var _jump_cooldown := 0.0
var speed := BASE_SPEED
var _torso_material: StandardMaterial3D


func _ready() -> void:
	floor_max_angle = deg_to_rad(50.0)
	set_collision_layer_value(4, true)
	set_collision_mask_value(1, true)
	set_collision_mask_value(2, true)
	set_collision_mask_value(4, true)
	_build_visuals()


func setup(target_player: Player) -> void:
	player = target_player


func _build_visuals() -> void:
	collision_shape = CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.8
	collision_shape.shape = capsule
	collision_shape.position = Vector3(0.0, 0.9, 0.0)
	add_child(collision_shape)

	body_root = Node3D.new()
	body_root.name = "Body"
	add_child(body_root)
	_add_box(body_root, Vector3(0.24, 0.52, 0.24), Color(0.22, 0.38, 0.22), Vector3(-0.11, 0.25, 0.0))
	_add_box(body_root, Vector3(0.24, 0.52, 0.24), Color(0.22, 0.38, 0.22), Vector3(0.11, 0.25, 0.0))
	var torso := _add_box(body_root, Vector3(0.54, 0.72, 0.34), Color(0.35, 0.55, 0.28), Vector3(0.0, 0.94, 0.0))
	_torso_material = torso.material_override as StandardMaterial3D
	_add_box(body_root, Vector3(0.10, 0.10, 0.55), Color(0.16, 0.22, 0.16), Vector3(0.48, 0.78, -0.35))
	_add_box(body_root, Vector3(0.32, 0.34, 0.32), Color(0.48, 0.66, 0.34), Vector3(0.0, 1.58, 0.0))
	_add_box(body_root, Vector3(0.34, 0.12, 0.34), Color(0.30, 0.46, 0.26), Vector3(0.0, 1.72, 0.0))

	_zombie_sfx = AudioStreamPlayer3D.new()
	_zombie_sfx.name = "ZombieSfx"
	_zombie_sfx.max_db = 3.0
	_zombie_sfx.unit_size = 12.0
	add_child(_zombie_sfx)

	_left_arm_pivot = Node3D.new()
	_left_arm_pivot.name = "LeftArmPivot"
	_left_arm_pivot.position = Vector3(-0.40, 1.22, 0.0)
	body_root.add_child(_left_arm_pivot)
	_add_box(_left_arm_pivot, Vector3(0.18, 0.52, 0.20), Color(0.26, 0.42, 0.24), Vector3(0.0, -0.24, 0.0))

	_right_arm_pivot = Node3D.new()
	_right_arm_pivot.name = "RightArmPivot"
	_right_arm_pivot.position = Vector3(0.40, 1.22, 0.0)
	body_root.add_child(_right_arm_pivot)
	_add_box(_right_arm_pivot, Vector3(0.18, 0.52, 0.20), Color(0.26, 0.42, 0.24), Vector3(0.0, -0.24, 0.0))
	_knife_mesh = _add_box(_right_arm_pivot, Vector3(0.045, 0.035, 0.46), Color(0.86, 0.82, 0.78), Vector3(0.0, -0.30, -0.30))
	_add_box(_right_arm_pivot, Vector3(0.05, 0.05, 0.12), Color(0.45, 0.24, 0.12), Vector3(0.0, -0.28, -0.04))


func _physics_process(delta: float) -> void:
	_attack_timer = maxf(0.0, _attack_timer - delta)
	_jump_cooldown = maxf(0.0, _jump_cooldown - delta)
	if _attack_anim_timer > 0.0:
		_attack_anim_timer = maxf(0.0, _attack_anim_timer - delta)
		var progress := 1.0 - _attack_anim_timer / ATTACK_ANIM_TIME
		if not _attack_impact_done and progress >= ATTACK_IMPACT_FRACTION:
			_attack_impact_done = true
			_apply_melee_hit()
		_update_attack_pose(progress)
	elif not _attack_impact_done:
		_attack_impact_done = true
		_update_attack_pose(1.0)
	if player == null:
		return
	if dead:
		_downed_time += delta
		var t := clampf(_downed_time / 0.8, 0.0, 1.0)
		var eased := 1.0 - pow(1.0 - t, 3.0)
		body_root.rotation.x = -PI * 0.5 * eased
		body_root.position.y = 0.06 * eased
		body_root.position.z = 0.0
		velocity = Vector3.ZERO
		move_and_slide()
		return
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0
	_alive_time += delta
	var multiplier := pow(2.0, floor(_alive_time / 20.0))
	speed = minf(BASE_SPEED * multiplier, 40.0)
	_face_player()
	_chase_player()
	if is_on_floor() and _jump_cooldown <= 0.0 and player.global_position.y - global_position.y > 1.2:
		velocity.y = 15.0
		_jump_cooldown = 1.4
	move_and_slide()
	_try_attack()


func _face_player() -> void:
	var to_player := player.global_position - global_position
	to_player.y = 0.0
	if to_player.length() < 0.01:
		return
	rotation.y = lerp_angle(rotation.y, atan2(-to_player.x, -to_player.z), 0.12)


func _chase_player() -> void:
	var to_player := player.global_position - global_position
	to_player.y = 0.0
	var distance := to_player.length()
	if distance > ATTACK_RANGE * 0.8:
		var direction := to_player.normalized()
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = 0.0
		velocity.z = 0.0


func _try_attack() -> void:
	var to_player := player.global_position - global_position
	to_player.y = 0.0
	if to_player.length() > ATTACK_RANGE or absf(player.global_position.y - global_position.y) > MAX_HEIGHT_DIFF or _attack_timer > 0.0 or _attack_anim_timer > 0.0 or player.dead:
		return
	var from := global_position + Vector3(0.0, 1.25, 0.0)
	var to := player.global_position + Vector3(0.0, 1.0, 0.0)
	var query := PhysicsRayQueryParameters3D.create(from, to, 0b1111)
	query.exclude = [get_rid()]
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if not (result.is_empty() or result.collider == player):
		return
	_attack_timer = ATTACK_COOLDOWN
	_attack_anim_timer = ATTACK_ANIM_TIME
	_attack_impact_done = false
	_update_attack_pose(0.0)
	if _zombie_sfx != null:
		_zombie_sfx.stream = SLASH_SOUND
		_zombie_sfx.volume_db = -5.0
		_zombie_sfx.pitch_scale = randf_range(0.92, 1.06)
		_zombie_sfx.play()


func _update_attack_pose(progress: float) -> void:
	if _right_arm_pivot == null or _left_arm_pivot == null:
		return
	if progress < 0.34:
		var t := progress / 0.34
		var eased := t * t * (3.0 - 2.0 * t)
		_right_arm_pivot.rotation.x = lerpf(0.0, 2.15, eased)
		_right_arm_pivot.rotation.y = lerpf(0.0, -0.55, eased)
		_left_arm_pivot.rotation.x = lerpf(0.0, 0.85, eased)
	elif progress < 0.72:
		var t := (progress - 0.34) / 0.38
		var eased := t * t * (3.0 - 2.0 * t)
		_right_arm_pivot.rotation.x = lerpf(2.15, -1.25, eased)
		_right_arm_pivot.rotation.y = lerpf(-0.55, 0.32, eased)
		_left_arm_pivot.rotation.x = lerpf(0.85, -0.35, eased)
	else:
		var t := (progress - 0.72) / 0.28
		var eased := t * t * (3.0 - 2.0 * t)
		_right_arm_pivot.rotation.x = lerpf(-1.25, 0.0, eased)
		_right_arm_pivot.rotation.y = lerpf(0.32, 0.0, eased)
		_left_arm_pivot.rotation.x = lerpf(-0.35, 0.0, eased)
	body_root.position.z = sin(progress * PI) * 0.12


func _apply_melee_hit() -> void:
	if player == null or dead or player.dead:
		return
	var offset := player.global_position - global_position
	var horizontal := Vector3(offset.x, 0.0, offset.z).length()
	if horizontal > ATTACK_RANGE or absf(offset.y) > MAX_HEIGHT_DIFF:
		return
	var from := global_position + Vector3(0.0, 1.25, 0.0)
	var to := player.global_position + Vector3(0.0, 1.0, 0.0)
	var query := PhysicsRayQueryParameters3D.create(from, to, 0b1111)
	query.exclude = [get_rid()]
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if not (result.is_empty() or result.collider == player):
		return
	var hit_normal := offset.normalized()
	player.take_damage(MELEE_DAMAGE, "body", to, hit_normal, self)
	var world := get_tree().current_scene
	Fx.spawn_tracer(world, global_position + Vector3(0.0, 1.35, 0.0), to, Color(0.7, 0.85, 0.45))
	attacked.emit()


func take_damage(amount: int, zone: String, hit_point: Vector3, hit_normal: Vector3, _source: Node3D) -> void:
	if dead:
		return
	health = maxi(0, health - amount)
	health_changed.emit(health, MAX_HEALTH)
	_flash_damage()
	if health == 0:
		dead = true
		_downed_time = 0.0
		died.emit()
		var tree := get_tree()
		if tree != null:
			tree.create_timer(2.0).timeout.connect(func() -> void:
				if is_instance_valid(self):
					queue_free())


func resolve_hit_zone(hit_point: Vector3) -> String:
	var relative_y := hit_point.y - global_position.y
	if relative_y >= HEAD_ZONE_HEIGHT:
		return "head"
	if relative_y >= LEG_ZONE_HEIGHT:
		return "body"
	return "legs"


func _flash_damage() -> void:
	if _torso_material == null:
		return
	var original := _torso_material.albedo_color
	_torso_material.albedo_color = Color(1.0, 0.85, 0.8)
	var tween := create_tween()
	tween.tween_property(_torso_material, "albedo_color", original, 0.12)


func _add_box(parent: Node3D, size: Vector3, color: Color, offset: Vector3) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.7
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = offset
	parent.add_child(mi)
	return mi
