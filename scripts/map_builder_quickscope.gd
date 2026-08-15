class_name MapBuilderQuickscope
extends Node3D


const ARENA_X := 70.0
const ARENA_Z := 40.0
const WALL_HEIGHT := 8.0
const DOOR_HALF_WIDTH := 3.2


func _ready() -> void:
	_add_environment()
	_add_ground()
	_add_door_walls()
	_add_boundary_walls()
	_add_lights()


func _add_environment() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.28, 0.42, 0.72)
	sky_mat.sky_horizon_color = Color(0.92, 0.70, 0.48)
	sky_mat.ground_bottom_color = Color(0.22, 0.20, 0.16)
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
	mat.albedo_color = Color(0.45, 0.42, 0.36)
	mat.roughness = 0.95
	_add_box(Vector3(0.0, -0.12, 0.0), Vector3(ARENA_X + 2.0, 0.24, ARENA_Z + 2.0), mat)

	var line_mat := StandardMaterial3D.new()
	line_mat.albedo_color = Color(0.92, 0.84, 0.62)
	line_mat.roughness = 0.8
	_add_box(Vector3(0.0, 0.015, 0.0), Vector3(ARENA_X - 6.0, 0.03, 1.4), line_mat)


func _add_door_walls() -> void:
	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.52, 0.48, 0.44)
	wall_mat.roughness = 0.82
	var segment_length := ARENA_Z * 0.5 - DOOR_HALF_WIDTH
	_add_box(Vector3(0.0, WALL_HEIGHT * 0.5, -(DOOR_HALF_WIDTH + segment_length * 0.5)), Vector3(0.7, WALL_HEIGHT, segment_length), wall_mat)
	_add_box(Vector3(0.0, WALL_HEIGHT * 0.5, DOOR_HALF_WIDTH + segment_length * 0.5), Vector3(0.7, WALL_HEIGHT, segment_length), wall_mat)

	var lintel_mat := StandardMaterial3D.new()
	lintel_mat.albedo_color = Color(0.62, 0.36, 0.28)
	lintel_mat.roughness = 0.75
	_add_box(Vector3(0.0, 6.25, 0.0), Vector3(0.9, 1.2, DOOR_HALF_WIDTH * 2.0 + 0.5), lintel_mat)

	var frame_mat := StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.72, 0.58, 0.42)
	frame_mat.roughness = 0.7
	_add_box(Vector3(0.0, 3.2, -DOOR_HALF_WIDTH - 0.25), Vector3(1.0, 6.4, 0.5), frame_mat)
	_add_box(Vector3(0.0, 3.2, DOOR_HALF_WIDTH + 0.25), Vector3(1.0, 6.4, 0.5), frame_mat)


func _add_boundary_walls() -> void:
	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.30, 0.33, 0.40)
	wall_mat.roughness = 0.85
	_add_box(Vector3(0.0, WALL_HEIGHT * 0.5, -ARENA_Z * 0.5 - 0.25), Vector3(ARENA_X + 1.0, WALL_HEIGHT, 0.5), wall_mat)
	_add_box(Vector3(0.0, WALL_HEIGHT * 0.5, ARENA_Z * 0.5 + 0.25), Vector3(ARENA_X + 1.0, WALL_HEIGHT, 0.5), wall_mat)
	_add_box(Vector3(-ARENA_X * 0.5 - 0.25, WALL_HEIGHT * 0.5, 0.0), Vector3(0.5, WALL_HEIGHT, ARENA_Z + 1.0), wall_mat)
	_add_box(Vector3(ARENA_X * 0.5 + 0.25, WALL_HEIGHT * 0.5, 0.0), Vector3(0.5, WALL_HEIGHT, ARENA_Z + 1.0), wall_mat)


func _add_lights() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52.0, -24.0, 0.0)
	sun.light_energy = 1.7
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 120.0
	add_child(sun)
	for i in range(4):
		var light := OmniLight3D.new()
		light.position = Vector3(-21.0 + i * 14.0, 6.0, -8.0 if i % 2 == 0 else 8.0)
		light.light_energy = 1.1
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
