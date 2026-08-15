class_name ScopeOverlay
extends Control


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.36
	var black := Color(0.0, 0.0, 0.0, 1.0)
	draw_rect(Rect2(0.0, 0.0, size.x, center.y - radius), black)
	draw_rect(Rect2(0.0, center.y + radius, size.x, size.y - center.y - radius), black)
	draw_rect(Rect2(0.0, center.y - radius, center.x - radius, radius * 2.0), black)
	draw_rect(Rect2(center.x + radius, center.y - radius, size.x - center.x - radius, radius * 2.0), black)

	draw_circle(center, radius, Color(0.0, 0.0, 0.0, 0.14))
	draw_arc(center, radius, 0.0, TAU, 72, Color(0.75, 0.82, 0.9, 0.95), 2.0)
	draw_arc(center, radius - 12.0, 0.0, TAU, 72, Color(0.35, 0.45, 0.55, 0.6), 1.0)

	var line_color := Color(0.85, 0.9, 0.95, 0.9)
	draw_line(Vector2(center.x, 0.0), Vector2(center.x, center.y - radius), line_color, 1.5)
	draw_line(Vector2(center.x, center.y + radius), Vector2(center.x, size.y), line_color, 1.5)
	draw_line(Vector2(0.0, center.y), Vector2(center.x - radius, center.y), line_color, 1.5)
	draw_line(Vector2(center.x + radius, center.y), Vector2(size.x, center.y), line_color, 1.5)
	draw_circle(center, 2.5, Color(1.0, 0.2, 0.15, 0.95))

	var dot_color := Color(1.0, 1.0, 1.0, 0.7)
	for side in [-1.0, 1.0]:
		draw_circle(center + Vector2(side * radius * 0.35, 0.0), 1.2, dot_color)
		draw_circle(center + Vector2(0.0, side * radius * 0.35), 1.2, dot_color)
