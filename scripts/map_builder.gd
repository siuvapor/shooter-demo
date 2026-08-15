class_name MapBuilder
extends Node3D


const ARENA_X := 44.0
const ARENA_Z := 28.0
const WALL_HEIGHT := 4.0


func _ready() -> void:
	_add_environment()
	_add_floor()
	_add_outer_walls()
	_add_central_wall()
	_add_lane_cover()
	_add_spawn_areas()
	_add_lights()


func _add_environment() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.32, 0.55, 0.78)
	sky_mat.sky_horizon_color = Color(0.86, 0.72, 0.52)
	sky_mat.ground_bottom_color = Color(0.28, 0.24, 0.18)
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


func _add_floor() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.43, 0.37, 0.29)
	mat.roughness = 0.95
	var noise := FastNoiseLite.new()
	noise.frequency = 0.1
	noise.seed = 4242
	var noise_texture := NoiseTexture2D.new()
	noise_texture.noise = noise
	noise_texture.width = 1024
	noise_texture.height = 1024
	noise_texture.seamless = true
	mat.albedo_texture = noise_texture
	mat.uv1_scale = Vector3(8.0, 8.0, 8.0)
	_add_box(Vector3(0.0, -0.12, 0.0), Vector3(ARENA_X + 2.0, 0.24, ARENA_Z + 2.0), mat)

	var lane_mat := StandardMaterial3D.new()
	lane_mat.albedo_color = Color(0.85, 0.30, 0.24, 0.55)
	lane_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	lane_mat.roughness = 0.6
	_add_box(Vector3(0.0, 0.01, 6.5), Vector3(ARENA_X - 4.0, 0.02, 1.2), lane_mat)
	lane_mat = lane_mat.duplicate()
	lane_mat.albedo_color = Color(0.25, 0.55, 0.85, 0.55)
	_add_box(Vector3(0.0, 0.01, -6.5), Vector3(ARENA_X - 4.0, 0.02, 1.2), lane_mat)


func _add_outer_walls() -> void:
	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.34, 0.38, 0.44)
	wall_mat.roughness = 0.82
	_add_box(Vector3(0.0, WALL_HEIGHT * 0.5, -ARENA_Z * 0.5 - 0.25), Vector3(ARENA_X + 1.0, WALL_HEIGHT, 0.5), wall_mat)
	_add_box(Vector3(0.0, WALL_HEIGHT * 0.5, ARENA_Z * 0.5 + 0.25), Vector3(ARENA_X + 1.0, WALL_HEIGHT, 0.5), wall_mat)
	_add_box(Vector3(-ARENA_X * 0.5 - 0.25, WALL_HEIGHT * 0.5, 0.0), Vector3(0.5, WALL_HEIGHT, ARENA_Z + 1.0), wall_mat)
	_add_box(Vector3(ARENA_X * 0.5 + 0.25, WALL_HEIGHT * 0.5, 0.0), Vector3(0.5, WALL_HEIGHT, ARENA_Z + 1.0), wall_mat)


func _add_central_wall() -> void:
	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.55, 0.32, 0.24)
	wall_mat.roughness = 0.78
	_add_box(Vector3(0.0, 1.35, 0.0), Vector3(36.0, 2.7, 2.0), wall_mat)
	var cap_mat := StandardMaterial3D.new()
	cap_mat.albedo_color = Color(0.76, 0.30, 0.22)
	cap_mat.roughness = 0.6
	_add_box(Vector3(0.0, 2.85, 0.0), Vector3(37.5, 0.25, 2.4), cap_mat)


func _add_lane_cover() -> void:
	var crate_mat := StandardMaterial3D.new()
	crate_mat.albedo_color = Color(0.62, 0.48, 0.30)
	crate_mat.roughness = 0.75
	var accent_mat := StandardMaterial3D.new()
	accent_mat.albedo_color = Color(0.76, 0.30, 0.22)
	accent_mat.roughness = 0.55

	_add_box(Vector3(-12.0, 0.5, 6.0), Vector3(2.0, 1.0, 2.0), crate_mat)
	_add_box(Vector3(-4.0, 0.7, 7.5), Vector3(2.0, 1.4, 2.0), crate_mat)
	_add_box(Vector3(4.0, 0.5, 6.0), Vector3(2.0, 1.0, 2.0), crate_mat)
	_add_box(Vector3(12.0, 1.0, 7.5), Vector3(1.8, 2.0, 1.8), accent_mat)

	_add_box(Vector3(12.0, 0.5, -6.0), Vector3(2.0, 1.0, 2.0), crate_mat)
	_add_box(Vector3(4.0, 0.7, -7.5), Vector3(2.0, 1.4, 2.0), crate_mat)
	_add_box(Vector3(-4.0, 0.5, -6.0), Vector3(2.0, 1.0, 2.0), crate_mat)
	_add_box(Vector3(-12.0, 1.0, -7.5), Vector3(1.8, 2.0, 1.8), accent_mat)

	_add_box(Vector3(0.0, 0.45, 4.6), Vector3(1.4, 0.9, 1.4), crate_mat)
	_add_box(Vector3(0.0, 0.45, -4.6), Vector3(1.4, 0.9, 1.4), crate_mat)
	_add_box(Vector3(-18.0, 0.6, 5.2), Vector3(1.6, 1.2, 1.6), crate_mat)
	_add_box(Vector3(-18.0, 0.6, -5.2), Vector3(1.6, 1.2, 1.6), crate_mat)
	_add_box(Vector3(18.0, 0.6, 5.2), Vector3(1.6, 1.2, 1.6), crate_mat)
	_add_box(Vector3(18.0, 0.6, -5.2), Vector3(1.6, 1.2, 1.6), crate_mat)


func _add_spawn_areas() -> void:
	var attacker_mat := StandardMaterial3D.new()
	attacker_mat.albedo_color = Color(0.22, 0.52, 0.86, 0.45)
	attacker_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var defender_mat := attacker_mat.duplicate()
	defender_mat.albedo_color = Color(0.86, 0.24, 0.22, 0.45)
	_add_box(Vector3(-19.0, 0.02, 0.0), Vector3(3.0, 0.04, ARENA_Z - 4.0), attacker_mat)
	_add_box(Vector3(19.0, 0.02, 0.0), Vector3(3.0, 0.04, ARENA_Z - 4.0), defender_mat)


func _add_lights() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, -28.0, 0.0)
	sun.light_energy = 1.5
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 90.0
	add_child(sun)
	var colors := [Color(0.95, 0.9, 0.8), Color(0.8, 0.9, 1.0)]
	for i in range(4):
		var light := OmniLight3D.new()
		light.position = Vector3(-16.0 + i * 10.0, 7.0, -7.0 if i % 2 == 0 else 7.0)
		light.light_color = colors[i % colors.size()]
		light.light_energy = 1.2
		light.omni_range = 15.0
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
