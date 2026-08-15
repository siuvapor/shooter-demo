class_name Tombstone
extends StaticBody3D


func setup(label: String, accent: Color) -> void:
	set_collision_layer_value(1, true)
	add_to_group("world")

	var stone_mat := StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.45, 0.48, 0.52)
	stone_mat.roughness = 0.8
	var slab := MeshInstance3D.new()
	slab.mesh = BoxMesh.new()
	(slab.mesh as BoxMesh).size = Vector3(0.6, 0.95, 0.14)
	slab.material_override = stone_mat
	slab.position = Vector3(0.0, 0.52, 0.0)
	add_child(slab)

	var trim_mat := StandardMaterial3D.new()
	trim_mat.albedo_color = accent
	trim_mat.roughness = 0.5
	var trim := MeshInstance3D.new()
	trim.mesh = BoxMesh.new()
	(trim.mesh as BoxMesh).size = Vector3(0.64, 0.10, 0.16)
	trim.material_override = trim_mat
	trim.position = Vector3(0.0, 0.98, 0.0)
	add_child(trim)

	var base_mat := StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.25, 0.27, 0.30)
	base_mat.roughness = 0.9
	var base := MeshInstance3D.new()
	base.mesh = BoxMesh.new()
	(base.mesh as BoxMesh).size = Vector3(0.78, 0.12, 0.34)
	base.material_override = base_mat
	base.position = Vector3(0.0, 0.06, 0.0)
	add_child(base)

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.6, 0.95, 0.14)
	shape.shape = box
	shape.position = Vector3(0.0, 0.52, 0.0)
	add_child(shape)
