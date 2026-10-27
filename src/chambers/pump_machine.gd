@tool
## La Bomba de la Cueva (while). Mientras el tanque tenga menos de limit, bomba.bombear().
class_name PumpMachine
extends RoundsMachine

const WATER := Color("3f9fe0")

var limit := 10


func setup(bus: EventBus, data: Dictionary, text: Callable, open_codex: Callable) -> void:
	super(bus, data, text, open_codex)
	limit = int(data.get("limit", 10))


## Niveles de arranque distintos, siempre por debajo del límite.
func make_values() -> Array:
	var values: Array = []
	while values.size() < rounds:
		var v := _rng.randi_range(1, limit - 2)
		if not v in values:
			values.append(v)
	return values


func api_for(start, record: Callable) -> Dictionary:
	var level := [start]
	return {
		"tanque": CallsAdapter.new("tanque", {"nivel": func(): return level[0]}),
		"bomba": CallsAdapter.new("bomba", {"bombear": func():
			level[0] += 1
			record.call("bombear")}),
	}


func summary(done: Array) -> String:
	return _times(done.size())


func wanted(start) -> String:
	return _times(limit - int(start))


func _times(n: int) -> String:
	return "" if n == 0 else _text.call("pump_times", {"n": n})


## Cuántas veces bombeó (lo dice el texto de did).
func _pumped() -> int:
	var found := RegEx.create_from_string("\\d+").search(did)
	return int(found.get_string()) if found else 0


func _draw() -> void:
	var tank := Rect2(-18, -64, 36, 60)
	draw_rect(tank.grow(2), OUTLINE)
	draw_rect(tank, Color("1a2230"))
	if value is int and value >= 0:
		var level := mini(int(value) + _pumped(), limit + 2)
		var h := tank.size.y * level / float(limit + 2)
		draw_rect(Rect2(tank.position.x, tank.end.y - h, tank.size.x, h), WATER)
		draw_rect(Rect2(tank.position.x, tank.end.y - h, tank.size.x, 2), WATER.lightened(0.4))
		_text_center(str(level), Vector2(0, tank.end.y - 6), 14, Color.WHITE)
	# Raya del límite
	var y := tank.end.y - tank.size.y * limit / float(limit + 2)
	draw_line(Vector2(tank.position.x - 6, y), Vector2(tank.end.x + 6, y), GOLD, 1.0)
	_text_center(str(limit), Vector2(tank.end.x + 14, y + 4), 10, GOLD)
	# Bomba con palanca
	draw_rect(Rect2(-46, -26, 16, 22).grow(1), OUTLINE)
	draw_rect(Rect2(-46, -26, 16, 22), WOOD)
	var up := 0.0 if did == "" else sin(Time.get_ticks_msec() / 90.0) * 4.0
	draw_line(Vector2(-38, -26), Vector2(-50, -40 + up), WOOD_DARK, 2.0)
	draw_line(Vector2(-30, -16), Vector2(-18, -16), Color("6a7a8a"), 3.0)
	_text_center("< %d: BOMBEAR" % limit, Vector2(0, -74), 10, GOLD)
	if mark.a > 0.0:
		draw_rect(Rect2(-56, -70, 112, 70), mark, false, 2.0)
