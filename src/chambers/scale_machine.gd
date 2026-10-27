@tool
## La Balanza de la Cima (for y acumulador). Suma las pesas de la lista y pone el total.
class_name ScaleMachine
extends RoundsMachine


func make_values() -> Array:
	var values: Array = []
	for i in rounds:
		var weights: Array = []
		for k in _rng.randi_range(3, 5):
			weights.append(_rng.randi_range(1, 9))
		values.append(weights)
	return values


func api_for(weights, record: Callable) -> Dictionary:
	return {
		"pesas": CallsAdapter.new("pesas", {"lista": func(): return weights.duplicate()}),
		"balanza": CallsAdapter.new("balanza", {"poner": func(n): record.call(ScriptContext.to_text(n))}),
	}


func wanted(weights) -> String:
	var total := 0
	for w in weights:
		total += int(w)
	return str(total)


func value_text(v) -> String:
	return ScriptContext.to_text(v)


func _draw() -> void:
	var right := mark == GOOD
	var tilt := 0.0 if right or did == "" else (6.0 if mark == BAD else 0.0)
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
	# Pesas a la izquierda, el total puesto a la derecha
	if value is Array:
		for i in value.size():
			var at := left + Vector2(-10 + (i % 3) * 8, 6 - (i / 3) * 7)
			draw_rect(Rect2(at, Vector2(7, 7)).grow(0.5), OUTLINE)
			draw_rect(Rect2(at, Vector2(7, 7)), GOLD)
		_text_center(ScriptContext.to_text(value), Vector2(0, -66), 11, CYAN)
	if did != "":
		_text_center(did, other + Vector2(0, 12), 14, mark if mark.a > 0.0 else Color.WHITE)
	if mark.a > 0.0:
		draw_rect(Rect2(-56, -78, 112, 80), mark, false, 2.0)
