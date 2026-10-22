@tool
## El Puente Colgante (Bosque, if). Si la carreta pesa más que limit, puente.reforzar().
class_name BridgeMachine
extends RoundsMachine

var limit := 10


func setup(bus: EventBus, data: Dictionary, text: Callable, open_codex: Callable) -> void:
	super(bus, data, text, open_codex)
	limit = int(data.get("limit", 10))


## Siempre hay una ronda pesada y una liviana.
func make_values() -> Array:
	var values := [_rng.randi_range(limit + 1, limit + 8), _rng.randi_range(2, limit)]
	for i in rounds - 2:
		values.append(_rng.randi_range(2, limit + 8))
	values.shuffle()
	return values


func api_for(weight: int, record: Callable) -> Dictionary:
	return {
		"carreta": CallsAdapter.new("carreta", {"peso": func(): return weight}),
		"puente": CallsAdapter.new("puente", {"reforzar": func(): record.call("reforzar")}),
	}


func wanted(weight: int) -> String:
	return "reforzar" if weight > limit else ""


func _draw() -> void:
	# Barranco
	draw_rect(Rect2(-60, -40, 120, 34), Color("0b0e14"))
	draw_rect(Rect2(-60, -40, 120, 3), Color("2c2034"))
	# Tablas
	var strong := did.contains("reforzar")
	for x in range(-58, 58, 8):
		draw_rect(Rect2(x, -27, 7, 8), WOOD)
		draw_rect(Rect2(x, -27, 7, 2), WOOD.lightened(0.2))
	draw_line(Vector2(-60, -30), Vector2(60, -30), WOOD_DARK, 1.0)
	draw_line(Vector2(-60, -18), Vector2(60, -18), WOOD_DARK, 1.0)
	if strong:
		for x in range(-50, 56, 20):
			draw_rect(Rect2(x, -31, 3, 16), GOLD)
	# Carreta en la orilla izquierda
	if value >= 0:
		var c := Vector2(-74, -24)
		draw_rect(Rect2(c - Vector2(10, 7), Vector2(20, 10)).grow(1), OUTLINE)
		draw_rect(Rect2(c - Vector2(10, 7), Vector2(20, 10)), WOOD_DARK)
		draw_circle(c + Vector2(-6, 4), 3.0, OUTLINE)
		draw_circle(c + Vector2(6, 4), 3.0, OUTLINE)
		_text_center(str(value), c + Vector2(0, 1), 12, mark if mark.a > 0.0 else GOLD)
	# Cartel con el límite
	_text_center("> %d: REFORZAR" % limit, Vector2(0, -48), 10, GOLD)
	if mark.a > 0.0:
		draw_rect(Rect2(-62, -42, 124, 38), mark, false, 2.0)
