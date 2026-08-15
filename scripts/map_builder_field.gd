class_name MapBuilderField
extends Node3D


const ARENA_X := 80.0
const ARENA_Z := 50.0
const WALL_HEIGHT := 4.0


func _ready() -> void:
	_add_environment()
	_add_ground()
	_add_static_cover()
	_add_destructible_covers()
	_add_bridge()
	_add_grass()
	_add_lights()


func _add_environment() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.36, 0.60, 0.84)
	sky_mat.sky_horizon_color = Color(0.90, 0.78, 0.55)
	sky_mat.ground_bottom_color = Color(0.24, 0.32, 0.18)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 1.4
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)


func _add_ground() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.38, 0.48, 0.30)
	mat.roughness = 0.95
	var noise := FastNoiseLite.new()
	noise.frequency = 0.08
	noise.seed = 777
	var noise_texture := NoiseTexture2D.new()
	noise_texture.noise = noise
	noise_texture.width = 1024
	noise_texture.height = 1024
	noise_texture.seamless = true
	mat.albedo_texture = noise_texture
	mat.uv1_scale = Vector3(8.0, 8.0, 8.0)
	_add_box(Vector3(0.0, -0.12, 0.0), Vector3(ARENA_X + 2.0, 0.24, ARENA_Z + 2.0), mat)

	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.32, 0.30, 0.26)
	wall_mat.roughness = 0.9
	_add_box(Vector3(0.0, WALL_HEIGHT * 0.5, -ARENA_Z * 0.5 - 0.25), Vector3(ARENA_X + 1.0, WALL_HEIGHT, 0.5), wall_mat)
	_add_box(Vector3(0.0, WALL_HEIGHT * 0.5, ARENA_Z * 0.5 + 0.25), Vector3(ARENA_X + 1.0, WALL_HEIGHT, 0.5), wall_mat)
	_add_box(Vector3(-ARENA_X * 0.5 - 0.25, WALL_HEIGHT * 0.5, 0.0), Vector3(0.5, WALL_HEIGHT, ARENA_Z + 1.0), wall_mat)
	_add_box(Vector3(ARENA_X * 0.5 + 0.25, WALL_HEIGHT * 0.5, 0.0), Vector3(0.5, WALL_HEIGHT, ARENA_Z + 1.0), wall_mat)


func _add_static_cover() -> void:
	var sand_mat := StandardMaterial3D.new()
	sand_mat.albedo_color = Color(0.72, 0.62, 0.38)
	sand_mat.roughness = 0.9
	_add_box(Vector3(-24.0, 0.7, 8.0), Vector3(4.0, 1.4, 1.0), sand_mat)
	_add_box(Vector3(24.0, 0.7, -8.0), Vector3(4.0, 1.4, 1.0), sand_mat)
	_add_box(Vector3(0.0, 0.6, 14.0), Vector3(6.0, 1.2, 0.8), sand_mat)
	_add_box(Vector3(-6.0, 0.6, -14.0), Vector3(6.0, 1.2, 0.8), sand_mat)

	var rock_mat := StandardMaterial3D.new()
	rock_mat.albedo_color = Color(0.48, 0.46, 0.42)
	rock_mat.roughness = 0.95
	_add_box(Vector3(-16.0, 0.75, -9.0), Vector3(2.0, 1.5, 2.0), rock_mat)
	_add_box(Vector3(16.0, 0.75, 9.0), Vector3(2.0, 1.5, 2.0), rock_mat)


func _add_destructible_covers() -> void:
	var crate_color := Color(0.62, 0.42, 0.22)
	var wood_color := Color(0.55, 0.36, 0.20)
	_add_destructible(Vector3(-30.0, 0.0, 12.0), Vector3(2.0, 1.2, 1.6), crate_color, 100)
	_add_destructible(Vector3(-20.0, 0.0, -12.0), Vector3(2.0, 1.2, 1.6), crate_color, 100)
	_add_destructible(Vector3(30.0, 0.0, -12.0), Vector3(2.0, 1.2, 1.6), crate_color, 100)
	_add_destructible(Vector3(20.0, 0.0, 12.0), Vector3(2.0, 1.2, 1.6), crate_color, 100)
	_add_destructible(Vector3(-8.0, 0.0, 6.0), Vector3(1.6, 1.0, 1.2), wood_color, 80)
	_add_destructible(Vector3(8.0, 0.0, -6.0), Vector3(1.6, 1.0, 1.2), wood_color, 80)
	_add_destructible(Vector3(0.0, 0.0, -8.0), Vector3(2.0, 1.1, 1.0), crate_color, 90)
	_add_destructible(Vector3(12.0, 0.0, 4.0), Vector3(1.4, 0.9, 1.4), wood_color, 70)
	_add_destructible(Vector3(-12.0, 0.0, -4.0), Vector3(1.4, 0.9, 1.4), wood_color, 70)


func _add_grass() -> void:
	var bush_color := Color(0.28, 0.52, 0.24)
	var tall_color := Color(0.40, 0.62, 0.28)
	for i in range(14):
		var x := randf_range(-36.0, 36.0)
		var z := randf_range(-22.0, 22.0)
		var grass := TallGrass.new()
		add_child(grass)
		grass.global_position = Vector3(x, 0.0, z)
		grass.setup(30, bush_color if i % 2 == 0 else tall_color)


func _add_bridge() -> void:
	var stone_mat := StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.58, 0.55, 0.50)
	stone_mat.roughness = 0.85
	var arch_mat := StandardMaterial3D.new()
	arch_mat.albedo_color = Color(0.48, 0.44, 0.40)
	arch_mat.roughness = 0.9
	var wood_mat := StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.52, 0.34, 0.20)
	wood_mat.roughness = 0.8

	_add_box(Vector3(0.0, 4.2, 0.0), Vector3(28.0, 0.5, 8.0), stone_mat)
	var ramp_angle := atan(4.2 / 6.0)
	_add_box_rotated(Vector3(17.0, 2.1, 0.0), Vector3(6.2, 0.4, 8.0), Vector3(0.0, 0.0, -ramp_angle), stone_mat)
	_add_box_rotated(Vector3(-17.0, 2.1, 0.0), Vector3(6.2, 0.4, 8.0), Vector3(0.0, 0.0, ramp_angle), stone_mat)

	_add_box(Vector3(-2.4, 1.3, 0.0), Vector3(1.0, 2.6, 6.2), arch_mat)
	_add_box(Vector3(2.4, 1.3, 0.0), Vector3(1.0, 2.6, 6.2), arch_mat)
	var arch_angles := [0.0, 30.0, 60.0, 90.0, 120.0, 150.0, 180.0]
	for angle_deg in arch_angles:
		var angle := deg_to_rad(angle_deg)
		var pos := Vector3(cos(angle) * 2.4, 1.5 + sin(angle) * 2.4, 0.0)
		_add_box_rotated(pos, Vector3(1.5, 0.7, 6.2), Vector3(0.0, 0.0, angle), arch_mat)

	_add_box(Vector3(0.0, 4.75, -4.0), Vector3(28.0, 0.35, 0.25), wood_mat)
	_add_box(Vector3(0.0, 4.75, 4.0), Vector3(28.0, 0.35, 0.25), wood_mat)

	_add_destructible(Vector3(0.0, 1.3, -3.5), Vector3(5.5, 2.6, 0.3), Color(0.52, 0.34, 0.20), 120)
	_add_destructible(Vector3(0.0, 1.3, 3.5), Vector3(5.5, 2.6, 0.3), Color(0.52, 0.34, 0.20), 120)


func _add_lights() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, -30.0, 0.0)
	sun.light_energy = 1.6
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 100.0
	add_child(sun)
	for i in range(4):
		var light := OmniLight3D.new()
		light.position = Vector3(-24.0 + i * 16.0, 6.0, -8.0 if i % 2 == 0 else 8.0)
		light.light_energy = 1.0
		light.omni_range = 16.0
		add_child(light)


func _add_box(pos: Vector3, size: Vector3, material: Material) -> void:
	var body := StaticBody3D.new()
	body.add_to_group("world")
	body.position = pos
	var mesh := MeshInstance3D.new()
	mesh.mesh = BoxMesh.new()
	(mesh.mesh as BoxMesh).size = size
	mesh.material_override = material
	body.add_child(mesh)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	add_child(body)


func _add_box_rotated(pos: Vector3, size: Vector3, rotation: Vector3, material: Material) -> void:
	var body := StaticBody3D.new()
	body.add_to_group("world")
	body.position = pos
	body.rotation = rotation
	var mesh := MeshInstance3D.new()
	mesh.mesh = BoxMesh.new()
	(mesh.mesh as BoxMesh).size = size
	mesh.material_override = material
	body.add_child(mesh)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	add_child(body)


func _add_destructible(pos: Vector3, size: Vector3, color: Color, hit_points: int) -> void:
	var cover := DestructibleCover.new()
	add_child(cover)
	cover.global_position = pos
	cover.setup(size, color, hit_points)
