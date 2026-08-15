class_name JumpPad
extends Area3D


var boost := 13.5


func setup(power: float, color: Color) -> void:
	boost = power
	collision_mask = 0b10
	monitoring = true
	body_entered.connect(_on_body_entered)
	_build_visuals(color)


func _build_visuals(color: Color) -> void:
	var disc_mat := StandardMaterial3D.new()
	disc_mat.albedo_color = color
	disc_mat.emission_enabled = true
	disc_mat.emission = color
	disc_mat.emission_energy_multiplier = 1.2
	var disc := MeshInstance3D.new()
	disc.mesh = CylinderMesh.new()
	var cylinder := disc.mesh as CylinderMesh
	cylinder.top_radius = 0.85
	cylinder.bottom_radius = 0.85
	cylinder.height = 0.12
	disc.material_override = disc_mat
	add_child(disc)

	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = Color(1.0, 1.0, 1.0, 0.9)
	var ring := MeshInstance3D.new()
	ring.mesh = CylinderMesh.new()
	var ring_cylinder := ring.mesh as CylinderMesh
	ring_cylinder.top_radius = 0.95
	ring_cylinder.bottom_radius = 0.95
	ring_cylinder.height = 0.04
	ring.material_override = ring_mat
	ring.position.y = 0.04
	add_child(ring)

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.0, 0.4, 2.0)
	shape.shape = box
	shape.position.y = 0.1
	add_child(shape)


func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		body.velocity.y = boost
