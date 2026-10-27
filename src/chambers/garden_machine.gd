@tool
## El Jardín de Macetas (Bosque, if/else). Agua < limit: regar(); si no: asolear().
class_name GardenMachine
extends RoundsMachine

var limit := 5


func setup(bus: EventBus, data: Dictionary, text: Callable, open_codex: Callable) -> void:
	super(bus, data, text, open_codex)
	limit = int(data.get("limit", 5))


## Siempre hay una maceta seca y una mojada.
func make_values() -> Array:
	var values := [_rng.randi_range(0, limit - 1), _rng.randi_range(limit, 9)]
	for i in rounds - 2:
		values.append(_rng.randi_range(0, 9))
	values.shuffle()
	return values


func api_for(water, record: Callable) -> Dictionary:
	return {"maceta": CallsAdapter.new("maceta", {
		"medir": func(): return water,
		"regar": func(): record.call("regar"),
		"asolear": func(): record.call("asolear"),
	})}


func wanted(water) -> String:
	return "regar" if water < limit else "asolear"


func _draw() -> void:
	# Maceta
	var pot := PackedVector2Array([Vector2(-14, -22), Vector2(14, -22), Vector2(10, 0), Vector2(-10, 0)])
	draw_colored_polygon(pot, Color("b0603a"))
	draw_polyline(pot + PackedVector2Array([pot[0]]), OUTLINE, 1.0)
	draw_rect(Rect2(-15, -25, 30, 4), Color("c8784a"))
	# Planta: más verde si el programa acertó
	var leaf := LEAF if mark != BAD else Color("8a7a3a")
	draw_line(Vector2(0, -25), Vector2(0, -44), leaf.darkened(0.2), 2.0)
	draw_circle(Vector2(-6, -38), 5.0, leaf)
	draw_circle(Vector2(6, -42), 5.0, leaf)
	draw_circle(Vector2(0, -48), 4.0, leaf.lightened(0.15))
	# Lo que hizo
	if did.contains("regar"):
		for i in 4:
			draw_circle(Vector2(-10 + i * 7, -56 + (i % 2) * 4), 1.6, CYAN)
	if did.contains("asolear"):
		draw_circle(Vector2(20, -58), 6.0, GOLD)
		for i in 8:
			var a := i * TAU / 8.0
			draw_line(Vector2(20, -58) + Vector2(cos(a), sin(a)) * 8.0, Vector2(20, -58) + Vector2(cos(a), sin(a)) * 11.0, GOLD, 1.0)
	_draw_sign(Vector2(-34, -30))
	_text_center("AGUA < %d: REGAR" % limit, Vector2(0, -76), 10, GOLD)
	if mark.a > 0.0:
		draw_rect(Rect2(-50, -72, 100, 74), mark, false, 2.0)
