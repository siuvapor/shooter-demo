class_name ParkourPortal
extends Area3D


var partner: ParkourPortal
var landing_pos := Vector3.ZERO
var cooldown := 0.0
var _ring: Node3D


func setup(color: Color) -> void:
	collision_mask = 0b10
	monitoring = true
	body_entered.connect(_on_body_entered)
	_build_visuals(color)


func link_to(other: ParkourPortal) -> void:
	partner = other
	other.partner = self


func set_landing(pos: Vector3) -> void:
	landing_pos = pos


func _process(delta: float) -> void:
	cooldown = maxf(0.0, cooldown - delta)
	if _ring != null:
		_ring.rotation.y += delta * 1.6


func _on_body_entered(body: Node3D) -> void:
	if body is Player and partner != null and cooldown <= 0.0:
		body.global_position = landing_pos
		body.velocity = Vector3.ZERO
		cooldown = 0.8
		partner.cooldown = 0.8


func _build_visuals(color: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.8
	var disc := MeshInstance3D.new()
	disc.mesh = CylinderMesh.new()
	var cylinder := disc.mesh as CylinderMesh
	cylinder.top_radius = 1.2
	cylinder.bottom_radius = 1.2
	cylinder.height = 0.1
	disc.material_override = mat
	disc.position.y = 0.05
	add_child(disc)

	_ring = Node3D.new()
	add_child(_ring)
	for i in range(12):
		var angle := TAU * float(i) / 12.0
		var marker := MeshInstance3D.new()
		marker.mesh = BoxMesh.new()
		(marker.mesh as BoxMesh).size = Vector3(0.16, 0.16, 0.16)
		marker.material_override = mat
		marker.position = Vector3(cos(angle) * 1.15, 0.25, sin(angle) * 1.15)
		_ring.add_child(marker)

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3.0, 1.8, 3.0)
	shape.shape = box
	shape.position.y = -0.25
	add_child(shape)
