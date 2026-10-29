@tool
## El Molino (capítulo 4, ORDER BY). Muele los sacos en el orden en que los trae la
## consulta: del más pesado al más liviano.
class_name MillMachine
extends SqlMachine

const SACKS := ["Trigo", "Avena", "Cebada", "Centeno", "Maíz", "Arroz", "Quinua", "Mijo"]

var ground := 0    # cuántos sacos ya entraron al molino


## 4 o 5 sacos con pesos distintos (así el orden no tiene empates).
func make_tables(_i: int) -> Array:
	var count := _rng.randi_range(4, 5)
	var names := _names(SACKS, count)
	var weights := _distinct(count, 2, 20)
	var rows: Array = []
	for k in count:
		rows.append([names[k], weights[k]])
	return [SqlTable.new("sacos", ["nombre", "peso"], rows)]


func show_round(i: int) -> void:
	super(i)
	ground = 0


## Los sacos entran al molino uno por uno, en el orden de la consulta.
func react(_right: bool) -> void:
	for k in got.size():
		ground = k + 1
		_bus.publish(GameEvents.MACHINE_STEP)
		await _wait(0.25)


func _draw() -> void:
	# Torre del molino
	var tower := PackedVector2Array([Vector2(-14, -4), Vector2(14, -4), Vector2(9, -50), Vector2(-9, -50)])
	draw_colored_polygon(tower, Color("c8b08a"))
	draw_polyline(tower + PackedVector2Array([tower[0]]), OUTLINE, 1.0)
	draw_rect(Rect2(-4, -16, 8, 12), WOOD_DARK)
	# Aspas que giran cuando trabaja
	var hub := Vector2(0, -46)
	var turn := Time.get_ticks_msec() / 400.0 if not got.is_empty() else 0.4
	for i in 4:
		var a := turn + i * TAU / 4.0
		var tip := hub + Vector2(cos(a), sin(a)) * 24.0
		draw_line(hub, tip, WOOD_DARK, 2.0)
		var side := Vector2(cos(a + 0.25), sin(a + 0.25)) * 20.0
		draw_colored_polygon(PackedVector2Array([hub + (tip - hub) * 0.3, tip, hub + side]), Color("efe4cf"))
	draw_circle(hub, 3.0, OUTLINE)
	# Fila de sacos a la derecha: el número dice en qué turno entró
	var order := got_values("nombre").map(func(v): return SqlEngine.show(v))
	for k in mini(order.size(), ground):
		var at := Vector2(26 + k * 13, -10)
		_sack(at, Color("d8b25a"))
		_text_center(str(k + 1), at + Vector2(0, 3), 6, mark if mark.a > 0.0 else OUTLINE)
	_draw_tables({"sacos": "nombre"}, -76)
	if mark.a > 0.0:
		draw_rect(Rect2(-40, -72, 120, 72), mark, false, 2.0)


func _sack(at: Vector2, color: Color) -> void:
	var r := Rect2(at - Vector2(6, 6), Vector2(12, 11))
	draw_rect(r.grow(1), OUTLINE)
	draw_rect(r, color)
	draw_rect(Rect2(at.x - 2, r.position.y - 2, 4, 2), color.darkened(0.25))
