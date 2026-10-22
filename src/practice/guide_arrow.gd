## Flecha dorada que salta sobre lo que hay que hacer en la práctica.
class_name GuideArrow
extends Node2D

var target := Vector2.INF

var _time := 0.0


func _init() -> void:
	z_index = 40


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	if target == Vector2.INF:
		return
	var tip := to_local(target) + Vector2(0, -9 - absf(sin(_time * 4.0)) * 6.0)
	var shape := PackedVector2Array([tip, tip + Vector2(-6, -7), tip + Vector2(-2.5, -7), tip + Vector2(-2.5, -14), tip + Vector2(2.5, -14), tip + Vector2(2.5, -7), tip + Vector2(6, -7)])
	draw_colored_polygon(shape, Color("ffc857"))
	draw_polyline(shape + PackedVector2Array([tip]), Color("5a3a10"), 1.0)
	draw_arc(to_local(target), 7.0 + sin(_time * 4.0), 0, TAU, 24, Color(1.0, 0.78, 0.34, 0.5), 1.0)
