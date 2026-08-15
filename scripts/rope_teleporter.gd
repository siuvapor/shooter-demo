class_name RopeTeleporter
extends Node3D


var start_pos := Vector3.ZERO
var end_pos := Vector3.ZERO
var active := false
var player: Player
var _area: Area3D


func setup(from_pos: Vector3, to_pos: Vector3, rope_color: Color) -> void:
	start_pos = from_pos
	end_pos = to_pos
	add_to_group("rope_teleporter")
	_build_visuals(rope_color)
	_build_area()


func _process(_delta: float) -> void:
	if active and player != null and Input.is_physical_key_pressed(KEY_E):
		teleport()


func teleport() -> void:
	if player == null:
		return
	player.global_position = end_pos + Vector3(0.0, 0.4, 0.0)
	player.velocity = Vector3.ZERO
	active = false


func _build_visuals(color: Color) -> void:
	var rope_mat := StandardMaterial3D.new()
	rope_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rope_mat.albedo_color = color
	var rope := MeshInstance3D.new()
	rope.mesh = ImmediateMesh.new()
	var im: ImmediateMesh = rope.mesh
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	im.surface_set_color(color)
	im.surface_add_vertex(start_pos + Vector3(0.0, 1.0, 0.0))
	im.surface_add_vertex(end_pos + Vector3(0.0, 1.0, 0.0))
	im.surface_end()
	rope.material_override = rope_mat
	add_child(rope)

	var post_mat := StandardMaterial3D.new()
	post_mat.albedo_color = Color(0.25, 0.28, 0.32)
	post_mat.roughness = 0.7
	for pos in [start_pos, end_pos]:
		var post := MeshInstance3D.new()
		post.mesh = BoxMesh.new()
		(post.mesh as BoxMesh).size = Vector3(0.22, 2.4, 0.22)
		post.material_override = post_mat
		post.position = pos + Vector3(0.0, 1.2, 0.0)
		add_child(post)

	var glow_mat := StandardMaterial3D.new()
	glow_mat.albedo_color = color
	glow_mat.emission_enabled = true
	glow_mat.emission = color
	var marker := MeshInstance3D.new()
	marker.mesh = SphereMesh.new()
	marker.material_override = glow_mat
	marker.position = start_pos + Vector3(0.0, 1.8, 0.0)
	marker.scale = Vector3(0.35, 0.35, 0.35)
	add_child(marker)


func _build_area() -> void:
	_area = Area3D.new()
	_area.name = "InteractionArea"
	_area.collision_mask = 0b10
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.4, 2.6, 2.4)
	shape.shape = box
	_area.add_child(shape)
	add_child(_area)
	_area.global_position = start_pos + Vector3(0.0, 1.2, 0.0)
	_area.body_entered.connect(_on_body_entered)
	_area.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		player = body
		active = true


func _on_body_exited(body: Node3D) -> void:
	if body == player:
		player = null
		active = false
