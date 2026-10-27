@tool
## El Molino (funciones con return). Llama a moler(sacos) y espera sacos * factor.
class_name MillMachine
extends FunctionRoundsMachine

var factor := 3


func setup(bus: EventBus, data: Dictionary, text: Callable, open_codex: Callable) -> void:
	super(bus, data, text, open_codex)
	factor = int(data.get("factor", 3))


func make_values() -> Array:
	var values: Array = []
	while values.size() < rounds:
		var v := _rng.randi_range(2, 9)
		if not v in values:
			values.append(v)
	return values


func wanted(sacks) -> String:
	return str(int(sacks) * factor)


func _draw() -> void:
	# Torre del molino
	var tower := PackedVector2Array([Vector2(-14, -4), Vector2(14, -4), Vector2(9, -50), Vector2(-9, -50)])
	draw_colored_polygon(tower, Color("c8b08a"))
	draw_polyline(tower + PackedVector2Array([tower[0]]), OUTLINE, 1.0)
	draw_rect(Rect2(-4, -16, 8, 12), WOOD_DARK)
	# Aspas que giran cuando trabaja
	var hub := Vector2(0, -46)
	var turn := Time.get_ticks_msec() / 400.0 if did != "" else 0.4
	for i in 4:
		var a := turn + i * TAU / 4.0
		var tip := hub + Vector2(cos(a), sin(a)) * 24.0
		draw_line(hub, tip, WOOD_DARK, 2.0)
		var side := Vector2(cos(a + 0.25), sin(a + 0.25)) * 20.0
		draw_colored_polygon(PackedVector2Array([hub + (tip - hub) * 0.3, tip, hub + side]), Color("efe4cf"))
	draw_circle(hub, 3.0, OUTLINE)
	# Sacos de trigo a la izquierda, harina a la derecha
	if value is int and value >= 0:
		_sack(Vector2(-36, -10), Color("d8b25a"))
		_text_center(str(value), Vector2(-36, -6), 12, mark if mark.a > 0.0 else Color.WHITE)
	if did != "":
		_sack(Vector2(36, -10), Color("f4efe4"))
		_text_center(did, Vector2(36, -6), 12, mark if mark.a > 0.0 else OUTLINE)
	_text_center("moler(%s) = %s × %d" % ["sacos", "sacos", factor], Vector2(0, -78), 10, GOLD)
	if mark.a > 0.0:
		draw_rect(Rect2(-54, -74, 108, 74), mark, false, 2.0)


func _sack(at: Vector2, color: Color) -> void:
	var r := Rect2(at - Vector2(9, 9), Vector2(18, 16))
	draw_rect(r.grow(1), OUTLINE)
	draw_rect(r, color)
	draw_rect(Rect2(at.x - 3, r.position.y - 3, 6, 3), color.darkened(0.25))
