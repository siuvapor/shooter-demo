class_name HitFeedback
extends Control


const FLASH_DURATION := 0.34
const DIRECTION_DURATION := 0.72
const MAX_FLASH_ALPHA := 0.24

var _flash_timer := 0.0
var _direction_timer := 0.0
var _direction := Vector2.RIGHT
var _has_direction := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	var changed := false
	if _flash_timer > 0.0:
		_flash_timer = maxf(0.0, _flash_timer - delta)
		changed = true
	if _direction_timer > 0.0:
		_direction_timer = maxf(0.0, _direction_timer - delta)
		changed = true
	if changed:
		queue_redraw()


func trigger(_amount: int, hit_direction: Vector3) -> void:
	_flash_timer = FLASH_DURATION
	_direction_timer = DIRECTION_DURATION
	_has_direction = false
	var camera := get_viewport().get_camera_3d()
	if camera != null and hit_direction.length_squared() > 0.000001:
		var basis := camera.global_transform.basis
		var relative := (-hit_direction.normalized()) as Vector3
		var screen_dir := Vector2(basis.x.dot(relative), basis.y.dot(relative))
		if screen_dir.length_squared() > 0.000001:
			_direction = screen_dir.normalized()
			_has_direction = true
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	if _flash_timer > 0.0:
		var t := _flash_timer / FLASH_DURATION
		var alpha := (1.0 - t) * MAX_FLASH_ALPHA
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.92, 0.08, 0.06, alpha * 0.28))
		var border_width := lerpf(8.0, 42.0, 1.0 - t)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.95, 0.1, 0.08, alpha * 0.9), false, border_width)
	if _has_direction and _direction_timer > 0.0:
		var p := _direction_timer / DIRECTION_DURATION
		var alpha := clampf(p * 1.4, 0.0, 1.0)
		var radius := 122.0 + (1.0 - p) * 24.0
		var angle := atan2(_direction.y, _direction.x)
		draw_arc(center, radius, angle - 0.45, angle + 0.45, 28, Color(0.95, 0.13, 0.10, alpha), 7.0)
		draw_arc(center, radius + 12.0, angle - 0.24, angle + 0.24, 22, Color(0.98, 0.42, 0.28, alpha * 0.7), 4.0)
		var tip := center + Vector2(cos(angle), sin(angle)) * radius
		var back := center + Vector2(cos(angle), sin(angle)) * (radius - 34.0)
		var perp := Vector2(-sin(angle), cos(angle)) * 13.0
		draw_colored_polygon(PackedVector2Array([tip, back + perp, back - perp]), Color(0.95, 0.13, 0.10, alpha))
