@tool
## El Puente Colgante (capítulo 2, WHERE con > y <). Se refuerza para las carretas
## que trae la consulta: las que pesan más que limit.
class_name BridgeMachine
extends SqlMachine

const CARTS := ["Roca", "Trigo", "Leña", "Sal", "Miel", "Lana", "Barro", "Maíz", "Hierro", "Pan"]

var limit := 10


func setup(bus: EventBus, data: Dictionary, text: Callable, open_codex: Callable) -> void:
	limit = int(data.get("limit", 10))
	super(bus, data, text, open_codex)


## 4 o 5 carretas: siempre hay pesadas y livianas, y una ronda trae una de justo limit.
func make_tables(i: int) -> Array:
	var count := _rng.randi_range(4, 5)
	var names := _names(CARTS, count)
	var weights: Array = [_rng.randi_range(limit + 1, limit + 8), _rng.randi_range(2, limit - 1)]
	if i == 1:
		weights.append(limit)
	# Las demás nunca pesan justo limit: esa queda solo para la ronda 2
	while weights.size() < count:
		var w := _rng.randi_range(2, limit + 7)
		weights.append(w if w < limit else w + 1)
	weights.shuffle()
	var rows: Array = []
	for k in count:
		rows.append([names[k], weights[k]])
	return [SqlTable.new("carretas", ["nombre", "peso"], rows)]


func _draw() -> void:
	# Barranco
	draw_rect(Rect2(-60, -40, 120, 34), Color("0b0e14"))
	draw_rect(Rect2(-60, -40, 120, 3), Color("2c2034"))
	# Tablas
	for x in range(-58, 58, 8):
		draw_rect(Rect2(x, -27, 7, 8), WOOD)
		draw_rect(Rect2(x, -27, 7, 2), WOOD.lightened(0.2))
	draw_line(Vector2(-60, -30), Vector2(60, -30), WOOD_DARK, 1.0)
	draw_line(Vector2(-60, -18), Vector2(60, -18), WOOD_DARK, 1.0)
	# Un poste dorado por cada carreta que trajo la consulta
	var picked := got.size()
	for k in mini(picked, 6):
		draw_rect(Rect2(-50 + k * 20, -31, 3, 16), GOLD)
	_draw_tables({"carretas": "nombre"}, -46)
	if mark.a > 0.0:
		draw_rect(Rect2(-62, -42, 124, 38), mark, false, 2.0)
