@tool
## Las Raíces Gemelas (for, if y return). factorizar(b, c) devuelve [p, q] con p + q = b y p · q = c.
class_name TwinsMachine
extends FunctionRoundsMachine


## Polinomios x² + bx + c con raíces enteras pequeñas.
func make_values() -> Array:
	var values: Array = []
	var kinds := ["mixed", "both", "square"]
	for i in rounds:
		var p := _rng.randi_range(1, 9)
		var q := _rng.randi_range(1, 9)
		match kinds[i % kinds.size()]:
			"mixed":
				q = -q
			"square":
				q = p
		values.append({"b": p + q, "c": p * q, "roots": [p, q]})
	return values


func args_for(v) -> Array:
	return [v.b, v.c]


## [p, q] en orden, así da igual cuál se devuelva primero.
func shown(returned) -> String:
	if typeof(returned) == TYPE_ARRAY and returned.size() == 2:
		var pair: Array = returned.map(func(x): return _whole(x))
		pair.sort()
		return ScriptContext.to_text(pair)
	return ScriptContext.to_text(returned)


func wanted(v) -> String:
	var pair: Array = v.roots.duplicate()
	pair.sort()
	return ScriptContext.to_text(pair)


func value_text(v) -> String:
	return polynomial(int(v.b), int(v.c))


## "x² + 3x − 10"
static func polynomial(b: int, c: int) -> String:
	var text := "x²"
	if b != 0:
		text += (" − " if b < 0 else " + ") + ("" if absi(b) == 1 else str(absi(b))) + "x"
	if c != 0:
		text += (" − " if c < 0 else " + ") + str(absi(c))
	return text


func _draw() -> void:
	# Dos árboles gemelos con las raíces a la vista
	for side in [-1, 1]:
		var base := Vector2(side * 26, -6)
		draw_rect(Rect2(base + Vector2(-3, -30), Vector2(6, 30)), WOOD_DARK)
		draw_circle(base + Vector2(0, -38), 13.0, OUTLINE)
		draw_circle(base + Vector2(0, -38), 12.0, LEAF if mark != BAD else Color("8a7a3a"))
		for k in 3:
			draw_line(base, base + Vector2(-8 + k * 8, 8), WOOD, 1.0)
	if value is Dictionary:
		_text_center(polynomial(int(value.b), int(value.c)), Vector2(0, -66), 12, CYAN)
	if did != "":
		_text_center(did, Vector2(0, -14), 12, mark if mark.a > 0.0 else Color.WHITE)
	if mark.a > 0.0:
		draw_rect(Rect2(-50, -80, 100, 82), mark, false, 2.0)
