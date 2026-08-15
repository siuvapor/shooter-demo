class_name Fx
extends RefCounted


static func spawn_tracer(parent: Node3D, from: Vector3, to: Vector3, color: Color) -> void:
	if parent == null:
		return
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	mesh.surface_set_color(color)
	mesh.surface_add_vertex(from)
	mesh.surface_add_vertex(to)
	mesh.surface_end()
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mi.material_override = mat
	parent.add_child(mi)
	var tween := parent.create_tween()
	tween.tween_interval(0.05)
	tween.tween_callback(mi.queue_free)


static func spawn_muzzle_flash(parent: Node3D, pos: Vector3, color := Color(1.0, 0.8, 0.3)) -> void:
	if parent == null:
		return
	var light := OmniLight3D.new()
	parent.add_child(light)
	light.global_position = pos
	light.light_color = color
	light.light_energy = 6.0
	light.omni_range = 3.0
	var tween := parent.create_tween()
	tween.tween_property(light, "light_energy", 0.0, 0.08)
	tween.tween_callback(light.queue_free)

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.0
	var sphere := MeshInstance3D.new()
	sphere.mesh = SphereMesh.new()
	sphere.material_override = mat
	parent.add_child(sphere)
	sphere.global_position = pos
	sphere.scale = Vector3(0.09, 0.09, 0.09)
	var flash_tween := parent.create_tween()
	flash_tween.tween_property(sphere, "scale", Vector3(0.3, 0.3, 0.3), 0.08)
	flash_tween.tween_callback(sphere.queue_free)


static func spawn_impact(parent: Node3D, pos: Vector3, normal: Vector3, color := Color(1.0, 0.7, 0.3)) -> void:
	if parent == null:
		return
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	var smesh := SphereMesh.new()
	smesh.material = mat
	var particles := CPUParticles3D.new()
	particles.mesh = smesh
	particles.one_shot = true
	particles.emitting = true
	particles.amount = 14
	particles.lifetime = 0.35
	particles.direction = normal
	particles.spread = 55.0
	particles.initial_velocity_min = 2.0
	particles.initial_velocity_max = 5.5
	particles.gravity = Vector3(0.0, -12.0, 0.0)
	particles.scale_amount_min = 0.035
	particles.scale_amount_max = 0.07
	particles.color = color
	parent.add_child(particles)
	particles.global_position = pos
	var tween := parent.create_tween()
	tween.tween_interval(0.6)
	tween.tween_callback(particles.queue_free)


static func spawn_damage_number(parent: Node3D, pos: Vector3, text: String, color := Color(1.0, 1.0, 1.0)) -> void:
	if parent == null:
		return
	var label := Label3D.new()
	label.text = text
	label.font_size = 96
	label.pixel_size = 0.008
	label.outline_size = 14
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(label)
	label.global_position = pos + Vector3(randf_range(-0.12, 0.12), 0.35, 0.0)
	var tween := parent.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y + 0.8, 0.7).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(label, "modulate:a", 0.0, 0.5).set_delay(0.2)
	tween.chain().tween_callback(label.queue_free)
