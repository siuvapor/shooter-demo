class_name ZombieEnemy
extends CharacterBody3D


signal health_changed(current: int, maximum: int)
signal died
signal attacked

const MAX_HEALTH := 120
const SPEED := 6.2
const MELEE_DAMAGE := 35
const ATTACK_RANGE := 2.6
const ATTACK_COOLDOWN := 1.1
const GRAVITY := 24.0
const HEAD_ZONE_HEIGHT := 1.36
const LEG_ZONE_HEIGHT := 0.58

var player: Player
var health := MAX_HEALTH
var dead := false
var body_root: Node3D
var collision_shape: CollisionShape3D
var _attack_timer := 0.0
var _downed_time := 0.0
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
	_add_box(body_root, Vector3(0.18, 0.52, 0.20), Color(0.26, 0.42, 0.24), Vector3(-0.40, 0.92, 0.0))
	_add_box(body_root, Vector3(0.18, 0.52, 0.20), Color(0.26, 0.42, 0.24), Vector3(0.40, 0.92, 0.0))
	_add_box(body_root, Vector3(0.10, 0.10, 0.55), Color(0.16, 0.22, 0.16), Vector3(0.48, 0.78, -0.35))
	_add_box(body_root, Vector3(0.32, 0.34, 0.32), Color(0.48, 0.66, 0.34), Vector3(0.0, 1.58, 0.0))
	_add_box(body_root, Vector3(0.34, 0.12, 0.34), Color(0.30, 0.46, 0.26), Vector3(0.0, 1.72, 0.0))


func _physics_process(delta: float) -> void:
	_attack_timer = maxf(0.0, _attack_timer - delta)
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
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0
	_face_player()
	_chase_player()
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
	if distance > ATTACK_RANGE * 0.85:
		var direction := to_player.normalized()
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = 0.0
		velocity.z = 0.0


func _try_attack() -> void:
	var to_player := player.global_position - global_position
	to_player.y = 0.0
	if to_player.length() > ATTACK_RANGE or _attack_timer > 0.0 or player.dead:
		return
	var from := global_position + Vector3(0.0, 1.5, 0.0)
	var to := player.camera.global_position
	var query := PhysicsRayQueryParameters3D.create(from, to, 0b1111)
	query.exclude = [get_rid()]
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if not (result.is_empty() or result.collider == player):
		return
	_attack_timer = ATTACK_COOLDOWN
	player.take_damage(MELEE_DAMAGE, "body", player.global_position + Vector3(0.0, 1.0, 0.0), global_position.direction_to(player.global_position), self)
	var world := get_tree().current_scene
	Fx.spawn_tracer(world, global_position + Vector3(0.0, 1.3, 0.0), player.global_position + Vector3(0.0, 1.0, 0.0), Color(0.7, 0.85, 0.45))
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
