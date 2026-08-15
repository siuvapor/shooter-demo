class_name MapBuilderTower
extends Node3D


const ARENA_X := 46.0
const ARENA_Z := 30.0
const WALL_HEIGHT := 4.0


func _ready() -> void:
	_add_environment()
	_add_ground_floor()
	_add_second_floor()
	_add_third_floor()
	_add_stairs()
	_add_ground_cover()
	_add_upper_cover()
	_add_lights()


func _add_environment() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.30, 0.55, 0.80)
	sky_mat.sky_horizon_color = Color(0.88, 0.70, 0.48)
	sky_mat.ground_bottom_color = Color(0.26, 0.22, 0.16)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 1.3
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.ssao_enabled = true
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)


func _add_ground_floor() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.42, 0.36, 0.28)
	mat.roughness = 0.95
	var noise := FastNoiseLite.new()
	noise.frequency = 0.1
	noise.seed = 5150
	var noise_texture := NoiseTexture2D.new()
	noise_texture.noise = noise
	noise_texture.width = 1024
	noise_texture.height = 1024
	noise_texture.seamless = true
	mat.albedo_texture = noise_texture
	mat.uv1_scale = Vector3(8.0, 8.0, 8.0)
	_add_box(Vector3(0.0, -0.12, 0.0), Vector3(ARENA_X + 2.0, 0.24, ARENA_Z + 2.0), mat)

	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.30, 0.36, 0.44)
	wall_mat.roughness = 0.85
	_add_box(Vector3(0.0, WALL_HEIGHT * 0.5, -ARENA_Z * 0.5 - 0.25), Vector3(ARENA_X + 1.0, WALL_HEIGHT, 0.5), wall_mat)
	_add_box(Vector3(0.0, WALL_HEIGHT * 0.5, ARENA_Z * 0.5 + 0.25), Vector3(ARENA_X + 1.0, WALL_HEIGHT, 0.5), wall_mat)
	_add_box(Vector3(-ARENA_X * 0.5 - 0.25, WALL_HEIGHT * 0.5, 0.0), Vector3(0.5, WALL_HEIGHT, ARENA_Z + 1.0), wall_mat)
	_add_box(Vector3(ARENA_X * 0.5 + 0.25, WALL_HEIGHT * 0.5, 0.0), Vector3(0.5, WALL_HEIGHT, ARENA_Z + 1.0), wall_mat)


func _add_second_floor() -> void:
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.48, 0.42, 0.33)
	floor_mat.roughness = 0.9
	_add_box(Vector3(0.0, 2.85, 0.0), Vector3(24.0, 0.30, 26.0), floor_mat)
	var rail_mat := StandardMaterial3D.new()
	rail_mat.albedo_color = Color(0.70, 0.34, 0.26)
	rail_mat.roughness = 0.6
	_add_box(Vector3(-12.0, 3.35, 0.0), Vector3(0.18, 0.7, 26.0), rail_mat)
	_add_box(Vector3(12.0, 3.35, 0.0), Vector3(0.18, 0.7, 26.0), rail_mat)
	_add_box(Vector3(0.0, 3.35, -13.0), Vector3(24.0, 0.7, 0.18), rail_mat)


func _add_third_floor() -> void:
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.56, 0.46, 0.34)
	floor_mat.roughness = 0.9
	_add_box(Vector3(2.0, 5.85, 0.0), Vector3(20.0, 0.30, 18.0), floor_mat)
	var rail_mat := StandardMaterial3D.new()
	rail_mat.albedo_color = Color(0.35, 0.62, 0.88)
	rail_mat.roughness = 0.6
	_add_box(Vector3(-8.0, 6.35, 0.0), Vector3(0.18, 0.7, 18.0), rail_mat)
	_add_box(Vector3(12.0, 6.35, 0.0), Vector3(0.18, 0.7, 18.0), rail_mat)
	_add_box(Vector3(2.0, 6.35, -9.0), Vector3(20.0, 0.7, 0.18), rail_mat)


func _add_stairs() -> void:
	var stair_mat := StandardMaterial3D.new()
	stair_mat.albedo_color = Color(0.62, 0.50, 0.34)
	stair_mat.roughness = 0.78
	_add_box(Vector3(-17.75, 0.55, 0.0), Vector3(2.5, 1.1, 8.0), stair_mat)
	_add_box(Vector3(-15.75, 1.65, 0.0), Vector3(2.5, 1.1, 8.0), stair_mat)
	_add_box(Vector3(-13.75, 2.75, 0.0), Vector3(2.5, 1.1, 8.0), stair_mat)

	_add_box(Vector3(6.75, 3.55, 0.0), Vector3(2.5, 1.1, 8.0), stair_mat)
	_add_box(Vector3(8.75, 4.65, 0.0), Vector3(2.5, 1.1, 8.0), stair_mat)
	_add_box(Vector3(10.75, 5.75, 0.0), Vector3(2.5, 1.1, 8.0), stair_mat)


func _add_ground_cover() -> void:
	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.50, 0.30, 0.24)
	wall_mat.roughness = 0.8
	_add_box(Vector3(0.0, 1.25, 0.0), Vector3(12.0, 2.5, 2.0), wall_mat)
	var crate_mat := StandardMaterial3D.new()
	crate_mat.albedo_color = Color(0.60, 0.46, 0.30)
	crate_mat.roughness = 0.75
	var accent_mat := StandardMaterial3D.new()
	accent_mat.albedo_color = Color(0.80, 0.30, 0.22)
	accent_mat.roughness = 0.55
	_add_box(Vector3(-16.0, 0.55, 5.5), Vector3(2.0, 1.1, 2.0), crate_mat)
	_add_box(Vector3(-7.0, 0.55, 7.0), Vector3(1.8, 1.1, 1.8), crate_mat)
	_add_box(Vector3(5.0, 0.55, 6.0), Vector3(2.0, 1.1, 2.0), crate_mat)
	_add_box(Vector3(15.0, 0.75, 7.0), Vector3(1.6, 1.5, 1.6), accent_mat)
	_add_box(Vector3(-15.0, 0.55, -6.0), Vector3(2.0, 1.1, 2.0), crate_mat)
	_add_box(Vector3(-5.0, 0.55, -7.0), Vector3(1.8, 1.1, 1.8), crate_mat)
	_add_box(Vector3(5.0, 0.55, -6.0), Vector3(2.0, 1.1, 2.0), crate_mat)
	_add_box(Vector3(15.0, 0.75, -7.0), Vector3(1.6, 1.5, 1.6), accent_mat)


func _add_upper_cover() -> void:
	var crate_mat := StandardMaterial3D.new()
	crate_mat.albedo_color = Color(0.52, 0.44, 0.34)
	crate_mat.roughness = 0.8
	var accent_mat := StandardMaterial3D.new()
	accent_mat.albedo_color = Color(0.35, 0.62, 0.88)
	accent_mat.roughness = 0.55
	_add_box(Vector3(-6.0, 3.55, 5.0), Vector3(2.0, 1.1, 2.0), crate_mat)
	_add_box(Vector3(4.0, 3.55, -5.0), Vector3(2.0, 1.1, 2.0), crate_mat)
	_add_box(Vector3(8.0, 4.05, 6.0), Vector3(1.8, 1.5, 1.8), accent_mat)
	_add_box(Vector3(-3.0, 3.55, -8.0), Vector3(2.0, 1.1, 2.0), crate_mat)

	_add_box(Vector3(-2.0, 6.35, 3.0), Vector3(1.8, 1.1, 1.8), crate_mat)
	_add_box(Vector3(6.0, 6.55, -3.0), Vector3(1.6, 1.5, 1.6), accent_mat)
	_add_box(Vector3(-6.0, 6.35, -5.0), Vector3(2.0, 1.1, 2.0), crate_mat)
	_add_box(Vector3(8.0, 6.55, 5.0), Vector3(1.6, 1.5, 1.6), crate_mat)


func _add_lights() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, -28.0, 0.0)
	sun.light_energy = 1.5
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 100.0
	add_child(sun)
	for i in range(6):
		var light := OmniLight3D.new()
		light.position = Vector3(-18.0 + i * 8.0, 7.0, -8.0 if i % 2 == 0 else 8.0)
		light.light_energy = 1.0
		light.omni_range = 14.0
		add_child(light)


func _add_box(pos: Vector3, size: Vector3, material: Material) -> void:
	var body := StaticBody3D.new()
	body.add_to_group("world")
	body.position = pos
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	body.add_child(mi)
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	body.add_child(shape)
	add_child(body)
