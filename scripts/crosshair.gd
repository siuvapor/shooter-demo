class_name Crosshair
extends Control


var player: Player
var _hit_time := -10.0
var _hit_head := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	queue_redraw()


func trigger_hitmarker(zone: String) -> void:
	_hit_time = Time.get_ticks_msec() / 1000.0
	_hit_head = zone == "head"


func _draw() -> void:
	var center := size / 2.0
	var gap := 7.0
	if player != null and player.weapon != null:
		gap = 6.0 + player.weapon.get_visual_spread() * 3.2
		if player.weapon.ads_amount > 0.5:
			gap *= 0.55
		gap = clampf(gap, 3.0, 26.0)
	var line_len := 10.0
	var thickness := 2.0
	var color := Color(1.0, 1.0, 1.0, 0.95)
	draw_rect(Rect2(center.x - gap - line_len, center.y - thickness * 0.5, line_len, thickness), color)
	draw_rect(Rect2(center.x + gap, center.y - thickness * 0.5, line_len, thickness), color)
	draw_rect(Rect2(center.x - thickness * 0.5, center.y - gap - line_len, thickness, line_len), color)
	draw_rect(Rect2(center.x - thickness * 0.5, center.y + gap, thickness, line_len), color)
	draw_rect(Rect2(center.x - 1.0, center.y - 1.0, 2.0, 2.0), color)

	if Time.get_ticks_msec() / 1000.0 - _hit_time < 0.12:
		var hit_color := Color(1.0, 0.12, 0.08) if _hit_head else Color(1.0, 1.0, 1.0)
		var hm := 7.0
		draw_line(center + Vector2(-hm, -hm), center + Vector2(-hm * 0.35, -hm * 0.35), hit_color, 2.0)
		draw_line(center + Vector2(hm, -hm), center + Vector2(hm * 0.35, -hm * 0.35), hit_color, 2.0)
		draw_line(center + Vector2(-hm, hm), center + Vector2(-hm * 0.35, hm * 0.35), hit_color, 2.0)
		draw_line(center + Vector2(hm, hm), center + Vector2(hm * 0.35, hm * 0.35), hit_color, 2.0)
