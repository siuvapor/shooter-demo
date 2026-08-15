class_name DestructibleCover
extends StaticBody3D


signal destroyed

var health := 100
var max_health := 100
var _material: StandardMaterial3D
var _base_color := Color.WHITE


func setup(size: Vector3, color: Color, hit_points := 100) -> void:
	health = hit_points
	max_health = hit_points
	_base_color = color
	add_to_group("destructible")
	set_collision_layer_value(1, true)

	_material = StandardMaterial3D.new()
	_material.albedo_color = color
	_material.roughness = 0.75
	var mesh := MeshInstance3D.new()
	mesh.mesh = BoxMesh.new()
	(mesh.mesh as BoxMesh).size = size
	mesh.material_override = _material
	add_child(mesh)

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	add_child(shape)


func take_damage(amount: int, zone: String, hit_point: Vector3, hit_normal: Vector3, _source: Node3D) -> void:
	if health <= 0:
		return
	health = maxi(0, health - amount)
	var damage_ratio := 1.0 - float(health) / float(max_health)
	_material.albedo_color = _base_color.darkened(damage_ratio * 0.65)
	Fx.spawn_impact(get_tree().current_scene, hit_point, hit_normal, _base_color)
	if health <= 0:
		destroyed.emit()
		Fx.spawn_impact(get_tree().current_scene, global_position + Vector3(0.0, 0.6, 0.0), Vector3.UP, _base_color)
		queue_free()
