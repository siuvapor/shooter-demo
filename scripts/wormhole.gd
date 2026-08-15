class_name Wormhole
extends Area3D


var partner: Wormhole
var cooldown := 0.0


func setup(color: Color) -> void:
	collision_mask = 0b10
	monitoring = true
	body_entered.connect(_on_body_entered)
	_build_visuals(color)


func _process(delta: float) -> void:
	cooldown = maxf(0.0, cooldown - delta)


func link_to(other: Wormhole) -> void:
	partner = other
	other.partner = self


func _on_body_entered(body: Node3D) -> void:
	if body is Player and partner != null and cooldown <= 0.0:
		body.global_position = partner.global_position + Vector3(0.0, 0.2, 1.2)
		body.velocity = Vector3.ZERO
		cooldown = 1.0
		partner.cooldown = 1.0


func _build_visuals(color: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.6
	var disc := MeshInstance3D.new()
	disc.mesh = CylinderMesh.new()
	var cylinder := disc.mesh as CylinderMesh
	cylinder.top_radius = 1.5
	cylinder.bottom_radius = 1.5
	cylinder.height = 0.12
	disc.material_override = mat
	add_child(disc)

	var inner := MeshInstance3D.new()
	inner.mesh = CylinderMesh.new()
	var inner_cylinder := inner.mesh as CylinderMesh
	inner_cylinder.top_radius = 1.0
	inner_cylinder.bottom_radius = 1.0
	inner_cylinder.height = 0.18
	var inner_mat := StandardMaterial3D.new()
	inner_mat.albedo_color = Color(0.0, 0.0, 0.0, 0.55)
	inner_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	inner_mat.emission_enabled = true
	inner_mat.emission = color.darkened(0.25)
	inner.material_override = inner_mat
	inner.position.y = 0.08
	add_child(inner)

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3.0, 1.2, 3.0)
	shape.shape = box
	shape.position.y = 0.5
	add_child(shape)
