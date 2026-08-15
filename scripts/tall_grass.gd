class_name TallGrass
extends StaticBody3D


signal destroyed

var health := 40
var max_health := 40
var _base_color := Color.GREEN
var _blades: Array[MeshInstance3D] = []


func setup(hit_points: int, color: Color) -> void:
	health = hit_points
	max_health = hit_points
	_base_color = color
	add_to_group("destructible")
	set_collision_layer_value(1, true)
	for i in range(7):
		var blade := MeshInstance3D.new()
		blade.mesh = BoxMesh.new()
		var box := blade.mesh as BoxMesh
		box.size = Vector3(0.18, randf_range(1.2, 1.8), 0.18)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color.lightened(randf_range(0.0, 0.12))
		mat.roughness = 0.85
		blade.material_override = mat
		blade.position = Vector3(randf_range(-0.65, 0.65), box.size.y * 0.5, randf_range(-0.65, 0.65))
		blade.rotation.y = randf_range(-0.4, 0.4)
		blade.rotation.z = randf_range(-0.12, 0.12)
		add_child(blade)
		_blades.append(blade)

	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(1.6, 1.8, 1.6)
	shape.shape = box_shape
	shape.position.y = 0.9
	add_child(shape)


func take_damage(amount: int, zone: String, hit_point: Vector3, hit_normal: Vector3, _source: Node3D) -> void:
	if health <= 0:
		return
	health = maxi(0, health - amount)
	Fx.spawn_impact(get_tree().current_scene, hit_point, hit_normal, _base_color)
	if health <= 0:
		destroyed.emit()
		Fx.spawn_impact(get_tree().current_scene, global_position + Vector3(0.0, 0.8, 0.0), Vector3.UP, _base_color)
		queue_free()
