@tool
## La Balanza de las Pesas (capítulo 5, INNER JOIN). Cada caja dice qué pesa lleva; la tabla
## pesas dice cuánto pesa cada una. Las cajas vacías no tienen pareja: INNER JOIN las deja fuera.
class_name ScaleMachine
extends SqlMachine

const BOXES := ["Azul", "Roja", "Verde", "Gris", "Blanca", "Negra"]
const EMPTY := 0    # pesa_id de las cajas vacías: no está en la tabla pesas

var total := 0


## 4 o 5 cajas; una o dos están vacías.
func make_tables(_i: int) -> Array:
	var weights: Array = []
	for id in range(1, 5):
		weights.append([id, _rng.randi_range(2, 9)])
	var count := _rng.randi_range(4, 5)
	var names := _names(BOXES, count)
	var empty := _rng.randi_range(1, 2)
	var boxes: Array = []
	for k in count:
		boxes.append([names[k], EMPTY if k < empty else _rng.randi_range(1, 4)])
	boxes.shuffle()
	return [SqlTable.new("cajas", ["caja", "pesa_id"], boxes), SqlTable.new("pesas", ["id", "kilos"], weights)]


func show_round(i: int) -> void:
	super(i)
	total = 0


## La balanza suma los kilos que trajo la consulta.
func react(_right: bool) -> void:
	total = 0
	for value in got_values("kilos"):
		if SqlEngine.is_number(value):
			total += int(value)
		_bus.publish(GameEvents.MACHINE_STEP)
		await _wait(0.2)


func _draw() -> void:
	var right := mark == GOOD
	var tilt := 0.0 if right or got.is_empty() else (6.0 if mark == BAD else 0.0)
	# Columna y brazo
	draw_rect(Rect2(-3, -48, 6, 46), WOOD_DARK)
	draw_rect(Rect2(-14, -4, 28, 4), WOOD_DARK)
	var left := Vector2(-36, -46 + tilt)
	var other := Vector2(36, -46 - tilt)
	draw_line(left, other, OUTLINE, 3.0)
	draw_line(left, other, Color("b08a50"), 1.0)
	for p in [left, other]:
		draw_line(p, p + Vector2(-10, 14), OUTLINE, 1.0)
		draw_line(p, p + Vector2(10, 14), OUTLINE, 1.0)
		draw_rect(Rect2(p + Vector2(-12, 14), Vector2(24, 3)), Color("8a6a3a"))
	# Una pesa por cada fila que trajo la consulta; a la derecha, el total
	for i in mini(got.size(), 6):
		var at := left + Vector2(-10 + (i % 3) * 8, 6 - (i / 3) * 7)
		draw_rect(Rect2(at, Vector2(7, 7)).grow(0.5), OUTLINE)
		draw_rect(Rect2(at, Vector2(7, 7)), GOLD)
	if not got.is_empty():
		_text_center("%d kg" % total, other + Vector2(0, 11), 7, mark if mark.a > 0.0 else Color.WHITE)
	_draw_tables({"cajas": "caja"}, -56)
	if mark.a > 0.0:
		draw_rect(Rect2(-56, -52, 112, 54), mark, false, 2.0)
