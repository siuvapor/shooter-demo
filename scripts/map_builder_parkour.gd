class_name MapBuilderParkour
extends Node3D


const START_POS := Vector3(-34.0, 0.0, 0.0)


func _ready() -> void:
	_add_environment()
	_add_start_platform()
	_add_floating_route()
	_add_moving_platform()
	_add_rotating_ring()
	_add_finish_spire()
	_add_ambient_rocks()
	_add_lights()


func _add_environment() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.08, 0.10, 0.22)
	sky_mat.sky_horizon_color = Color(0.38, 0.20, 0.52)
	sky_mat.ground_bottom_color = Color(0.03, 0.05, 0.10)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 1.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.30, 0.18, 0.48)
	env.fog_density = 0.012
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)


func _add_start_platform() -> void:
	_add_box_body(self, START_POS, Vector3(5.0, 0.5, 5.0), Color(0.30, 0.34, 0.46), false)
	_add_glow_marker(Vector3(-34.0, 0.8, 0.0), Color(0.45, 0.9, 1.0), 0.7)


func _add_floating_route() -> void:
	var route := [
		{"pos": Vector3(-30.0, 0.9, 0.0), "size": Vector3(2.3, 0.4, 2.3)},
		{"pos": Vector3(-27.0, 1.8, -1.2), "size": Vector3(2.1, 0.4, 2.1)},
		{"pos": Vector3(-24.0, 2.7, 1.2), "size": Vector3(2.1, 0.4, 2.1)},
		{"pos": Vector3(-21.0, 3.6, -1.2), "size": Vector3(2.0, 0.4, 2.0)},
		{"pos": Vector3(-18.0, 4.5, 1.2), "size": Vector3(2.0, 0.4, 2.0)},
		{"pos": Vector3(-15.0, 5.4, 0.0), "size": Vector3(1.9, 0.4, 1.9)},
		{"pos": Vector3(-12.0, 6.3, -0.8), "size": Vector3(1.9, 0.4, 1.9)},
		{"pos": Vector3(-9.0, 7.2, 0.8), "size": Vector3(1.8, 0.4, 1.8)},
		{"pos": Vector3(-6.0, 8.1, 0.0), "size": Vector3(1.8, 0.4, 1.8)},
		{"pos": Vector3(-3.0, 9.0, 0.0), "size": Vector3(1.8, 0.4, 1.8)},
	]
	for i in route.size():
		var entry: Dictionary = route[i]
		var t := float(i) / float(maxi(route.size() - 1, 1))
		var color := Color(0.28, 0.48, 0.72).lerp(Color(0.78, 0.42, 0.90), t)
		_add_box_body(self, entry["pos"], entry["size"], color, false)
		_add_glow_marker(entry["pos"] + Vector3(0.0, 0.32, 0.0), color.lightened(0.35), 0.42)


func _add_moving_platform() -> void:
	var holder := Node3D.new()
	holder.name = "MovingPlatform"
	holder.position = Vector3(0.0, 9.8, 0.0)
	add_child(holder)
	_add_box_body(holder, Vector3.ZERO, Vector3(1.7, 0.35, 1.7), Color(0.95, 0.62, 0.28), true)
	_add_glow_marker(Vector3.ZERO, Color(0.95, 0.72, 0.35), 0.5, holder)
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(holder, "position", Vector3(4.0, 9.8, 0.0), 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(holder, "position", Vector3(0.0, 9.8, 0.0), 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _add_rotating_ring() -> void:
	var spinner := Node3D.new()
	spinner.name = "RotatingRing"
	spinner.position = Vector3(7.0, 9.9, 0.0)
	add_child(spinner)
	for i in range(4):
		var angle := TAU * float(i) / 4.0 + PI * 0.25
		var pos := Vector3(cos(angle) * 2.0, 0.0, sin(angle) * 2.0)
		_add_box_body(spinner, pos, Vector3(1.5, 0.28, 0.7), Color(0.35, 0.9, 0.95), true)
	for i in range(18):
		var angle := TAU * float(i) / 18.0
		var pos := Vector3(cos(angle) * 2.0, 0.0, sin(angle) * 2.0)
		_add_glow_marker(pos, Color(0.35, 0.9, 0.95), 0.16, spinner)
	var spin := create_tween()
	spin.set_loops()
	spin.tween_property(spinner, "rotation:y", TAU, 5.5).set_trans(Tween.TRANS_LINEAR)


func _add_finish_spire() -> void:
	_add_box_body(self, Vector3(12.0, 11.0, 0.0), Vector3(3.2, 0.5, 3.2), Color(0.92, 0.68, 0.32), false)
	_add_glow_marker(Vector3(12.0, 11.8, 0.0), Color(1.0, 0.85, 0.35), 1.2)
	var beacon := OmniLight3D.new()
	beacon.position = Vector3(12.0, 12.6, 0.0)
	beacon.light_color = Color(1.0, 0.85, 0.35)
	beacon.light_energy = 3.0
	beacon.omni_range = 8.0
	add_child(beacon)


func _add_ambient_rocks() -> void:
	var rock_positions := [
		Vector3(-26.0, 0.2, 3.0),
		Vector3(-18.0, 3.2, -3.5),
		Vector3(-9.0, 5.8, 3.2),
		Vector3(0.0, 7.2, -3.0),
		Vector3(8.0, 6.4, 3.4),
		Vector3(14.0, 8.8, -2.8),
	]
	for pos in rock_positions:
		_add_box_body(self, pos, Vector3(1.6, 0.3, 1.6), Color(0.22, 0.26, 0.38), false)


func _add_lights() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52.0, -22.0, 0.0)
	sun.light_energy = 1.8
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 140.0
	add_child(sun)
	for i in range(5):
		var light := OmniLight3D.new()
		light.position = Vector3(-28.0 + i * 10.0, 6.0 + float(i) * 1.5, -4.0 if i % 2 == 0 else 4.0)
		light.light_color = Color(0.55, 0.70, 1.0).lerp(Color(1.0, 0.55, 0.90), float(i) / 4.0)
		light.light_energy = 1.3
		light.omni_range = 13.0
		add_child(light)


func _add_box_body(parent: Node3D, pos: Vector3, size: Vector3, color: Color, animated: bool) -> Node3D:
	var body: Node3D
	if animated:
		body = AnimatableBody3D.new()
	else:
		body = StaticBody3D.new()
	body.add_to_group("world")
	body.position = pos
	var mesh := MeshInstance3D.new()
	mesh.mesh = BoxMesh.new()
	(mesh.mesh as BoxMesh).size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.72
	mat.metallic = 0.35
	mesh.material_override = mat
	body.add_child(mesh)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	parent.add_child(body)
	return body


func _add_glow_marker(pos: Vector3, color: Color, scale: float, parent: Node3D = self) -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.6
	var marker := MeshInstance3D.new()
	marker.mesh = SphereMesh.new()
	marker.material_override = mat
	marker.position = pos
	marker.scale = Vector3(scale, scale, scale)
	parent.add_child(marker)
