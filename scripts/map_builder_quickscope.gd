class_name MapBuilderQuickscope
extends Node3D


const ARENA_X := 70.0
const ARENA_Z := 40.0
const WALL_HEIGHT := 8.0
const DOOR_HALF_WIDTH := 3.2
const MEME_TEXTURES := [
	"res://assets/memes/172459525196e095266e6924f7.jpg",
	"res://assets/memes/99.jpg",
	"res://assets/memes/OIP-C (2).webp",
	"res://assets/memes/OIP-C (3).webp",
	"res://assets/memes/OIP-C.webp",
]


func _ready() -> void:
	_add_environment()
	_add_ground()
	_add_door_walls()
	_add_boundary_walls()
	_add_distraction_decals()
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


func _add_distraction_decals() -> void:
	if _add_meme_posters():
		return
	_add_poster(Vector3(-0.38, 2.9, -9.0), PI * 0.5, "这里有人?", Color(0.95, 0.25, 0.20))
	_add_poster(Vector3(-0.38, 4.7, -14.0), PI * 0.5, "别看左边", Color(0.30, 0.82, 1.0))
	_add_poster(Vector3(-0.38, 3.4, 9.0), PI * 0.5, "假动作", Color(1.0, 0.80, 0.22))
	_add_poster(Vector3(-0.38, 5.5, 14.0), PI * 0.5, "下一秒爆头", Color(0.95, 0.42, 1.0))
	_add_poster(Vector3(-0.46, 6.3, 0.0), PI * 0.5, "别相信门", Color(1.0, 0.55, 0.18))


func _add_meme_posters() -> bool:
	var slots := [
		{"pos": Vector3(-0.38, 4.0, -15.8), "rot": PI * 0.5, "cover": Vector2(8.5, 7.6), "fit": false},
		{"pos": Vector3(-0.38, 4.0, -7.4), "rot": PI * 0.5, "cover": Vector2(8.5, 7.6), "fit": false},
		{"pos": Vector3(-0.38, 4.0, 7.4), "rot": PI * 0.5, "cover": Vector2(8.5, 7.6), "fit": false},
		{"pos": Vector3(-0.38, 4.0, 15.8), "rot": PI * 0.5, "cover": Vector2(8.5, 7.6), "fit": false},
		{"pos": Vector3(-0.46, 6.3, 0.0), "rot": PI * 0.5, "cover": Vector2(6.4, 1.1), "fit": true},
	]
	var placed := false
	for i in MEME_TEXTURES.size():
		var texture := load(MEME_TEXTURES[i]) as Texture2D
		if texture == null:
			continue
		var slot: Dictionary = slots[i % slots.size()]
		_add_meme_poster(texture, slot["pos"], slot["rot"], slot["cover"], slot["fit"])
		placed = true
	return placed


func _add_meme_poster(texture: Texture2D, pos: Vector3, rot_y: float, cover_size: Vector2, fit: bool) -> void:
	var sprite := Sprite3D.new()
	sprite.texture = texture
	var texture_size := texture.get_size()
	if fit:
		sprite.pixel_size = minf(cover_size.x / texture_size.x, cover_size.y / texture_size.y)
	else:
		sprite.pixel_size = maxf(cover_size.x / texture_size.x, cover_size.y / texture_size.y)
	sprite.position = pos
	sprite.rotation.y = rot_y
	add_child(sprite)


func _add_poster(pos: Vector3, rot_y: float, text: String, accent: Color) -> void:
	var sprite := Sprite3D.new()
	sprite.texture = _make_poster_texture(accent)
	sprite.pixel_size = 0.009
	sprite.position = pos
	sprite.rotation.y = rot_y
	add_child(sprite)

	var label := Label3D.new()
	label.text = text
	label.font_size = 96
	label.pixel_size = 0.009
	label.outline_size = 16
	label.modulate = Color.WHITE
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = pos + Vector3(-0.06, 0.0, 0.0)
	add_child(label)

	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(label, "modulate:a", 0.35, 0.55)
	tween.tween_property(label, "modulate:a", 1.0, 0.55)


func _make_poster_texture(accent: Color) -> ImageTexture:
	var image := Image.create(256, 256, false, Image.FORMAT_RGBA8)
	var dark := Color(0.08, 0.09, 0.14, 1.0)
	for y in range(256):
		for x in range(256):
			var stripe := ((x + y) / 32) % 2 == 0
			var px := accent if stripe else dark
			image.set_pixel(x, y, px)
	for radius in [112, 78, 44]:
		var ring_color := Color(1.0, 1.0, 1.0, 0.92) if radius > 90 else accent.lightened(0.45)
		for i in range(360):
			var angle := deg_to_rad(float(i))
			var x := int(128.0 + cos(angle) * radius)
			var y := int(128.0 + sin(angle) * radius)
			if x >= 0 and x < 256 and y >= 0 and y < 256:
				image.set_pixel(x, y, ring_color)
	return ImageTexture.create_from_image(image)


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
