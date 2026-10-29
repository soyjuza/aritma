@tool
## La Compuerta (capítulo 1, SELECT de una columna). Sube hasta el nivel de la tabla sensor.
class_name LockMachine
extends SqlMachine

const STONE := Color("4a4560")
const STONE_LIGHT := Color("6e6790")
const STONE_DARK := Color("2c2840")
const BRONZE := Color("b48a4e")
const BRONZE_DARK := Color("7a5a2e")
const TOP := 12.0                              # nivel más alto del medidor
const HOLE := Rect2(-26, -88, 52, 88)          # hueco de la compuerta
const COLORS := ["rojo", "azul", "verde", "dorado"]

var level := 0.0           # altura de la compuerta, en niveles

@onready var _light: PointLight2D = $Luz


func setup(bus: EventBus, data: Dictionary, text: Callable, open_codex: Callable) -> void:
	super(bus, data, text, open_codex)
	view_focus = Vector2(0, -50)


func status_text() -> String:
	return _text.call("lock_status", {"round": _round + 1, "of": rounds})


## Una sola fila: el color del sensor, su nivel y la hora.
func make_tables(i: int) -> Array:
	var levels := [_rng.randi_range(3, 6), _rng.randi_range(7, 9), _rng.randi_range(10, 11)]
	return [SqlTable.new("sensor", ["color", "nivel", "hora"], [[COLORS[_rng.randi() % COLORS.size()], levels[i % 3], _rng.randi_range(1, 12)]])]


func show_round(i: int) -> void:
	super(i)
	level = 0.0


## La compuerta sube al número que trajo la consulta (si trajo un número).
func react(_right: bool) -> void:
	var values := got_values("nivel")
	var target := 0.0
	if not values.is_empty() and SqlEngine.is_number(values[0]):
		target = clampf(float(values[0]), 0.0, TOP + 2.0)
	var t := create_tween()
	t.tween_property(self, "level", target, 0.3 + 0.05 * target)
	await t.finished


func mark_solved() -> void:
	level = TOP
	if _light:
		create_tween().tween_property(_light, "energy", 1.4, 0.4)
	super()


func _sensor() -> int:
	var t := table("sensor")
	return int(t.rows[0][1]) if t and not t.rows.is_empty() else -1


# ------------------------------------------------------------------ dibujo

func _draw() -> void:
	# Fondo del hueco
	draw_rect(HOLE, Color("0b0e14"))
	# La reja sube según el nivel
	var lift := HOLE.size.y * clampf(level / TOP, 0.0, 1.0)
	var gate := Rect2(HOLE.position.x, HOLE.position.y, HOLE.size.x, HOLE.size.y - lift)
	if gate.size.y > 0.5:
		for x in range(int(gate.position.x) + 3, int(gate.end.x), 7):
			draw_rect(Rect2(x, gate.position.y, 3, gate.size.y), BRONZE)
			draw_rect(Rect2(x + 2, gate.position.y, 1, gate.size.y), BRONZE_DARK)
		draw_rect(Rect2(gate.position.x, gate.end.y - 4, gate.size.x, 4), BRONZE_DARK)
	# Pilares y dintel
	for px in [-40.0, 26.0]:
		var pillar := Rect2(px, -96, 14, 96)
		draw_rect(pillar.grow(1), OUTLINE)
		draw_rect(pillar, STONE)
		draw_rect(Rect2(pillar.position, Vector2(3, pillar.size.y)), STONE_LIGHT)
		draw_rect(Rect2(pillar.end.x - 3, pillar.position.y, 3, pillar.size.y), STONE_DARK)
	var lintel := Rect2(-44, -108, 88, 14)
	draw_rect(lintel.grow(1), OUTLINE)
	draw_rect(lintel, BRONZE)
	_text_center("SELECT nivel", Vector2(0, -98), 6, OUTLINE)
	# Medidor en el pilar derecho
	for n in int(TOP) + 1:
		var y := -4.0 - (HOLE.size.y - 8.0) * n / TOP
		draw_rect(Rect2(30, y, 6 if n % 3 == 0 else 3, 1), CYAN.darkened(0.3))
	var my := -4.0 - (HOLE.size.y - 8.0) * clampf(level / TOP, 0.0, 1.0)
	draw_rect(Rect2(28, my - 1.5, 10, 3), mark if mark.a > 0.0 else GOLD)
	# Sensor en el pilar izquierdo
	var box := Rect2(-58, -62, 22, 18)
	draw_rect(box.grow(1), OUTLINE)
	draw_rect(box, Color("101820"))
	if _sensor() >= 0:
		_text_center(str(_sensor()), box.get_center() + Vector2(0, 4), 8, CYAN)
	if mark.a > 0.0:
		_text_center(str(int(round(level))), Vector2(46, my + 3), 6, mark)
	_draw_tables({}, -116)
