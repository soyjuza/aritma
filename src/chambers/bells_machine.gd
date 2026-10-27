@tool
## Las Campanas de la Cima (for y listas). Toca cada nota de partitura.leer() en orden.
class_name BellsMachine
extends RoundsMachine

const BRONZE := Color("d8a25a")

var bells := 5


func setup(bus: EventBus, data: Dictionary, text: Callable, open_codex: Callable) -> void:
	super(bus, data, text, open_codex)
	bells = int(data.get("bells", 5))


## Partituras de 3 a 5 notas.
func make_values() -> Array:
	var values: Array = []
	for i in rounds:
		var song: Array = []
		for k in _rng.randi_range(3, 5):
			song.append(_rng.randi_range(1, bells))
		values.append(song)
	return values


func api_for(song, record: Callable) -> Dictionary:
	return {
		"partitura": CallsAdapter.new("partitura", {"leer": func(): return song.duplicate()}),
		"campana": CallsAdapter.new("campana", {"tocar": func(n): record.call(ScriptContext.to_text(n))}),
	}


func summary(done: Array) -> String:
	return ", ".join(done)


func wanted(song) -> String:
	return ", ".join(song.map(func(n): return str(n)))


func value_text(v) -> String:
	return ScriptContext.to_text(v)


func _draw() -> void:
	draw_rect(Rect2(-60, -62, 120, 5).grow(1), OUTLINE)
	draw_rect(Rect2(-60, -62, 120, 5), WOOD)
	var rung := did.split(", ", false)
	for i in bells:
		var x := -48 + i * 24
		var ringing := str(i + 1) in rung
		var swing := sin(Time.get_ticks_msec() / 120.0 + i) * 3.0 if ringing else 0.0
		var top := Vector2(x, -57)
		draw_line(top, top + Vector2(swing, 8), OUTLINE, 1.0)
		var c := top + Vector2(swing, 18)
		var bell := PackedVector2Array([c + Vector2(-5, -10), c + Vector2(5, -10), c + Vector2(9, 4), c + Vector2(-9, 4)])
		draw_colored_polygon(bell, BRONZE.lightened(0.25) if ringing else BRONZE)
		draw_polyline(bell + PackedVector2Array([bell[0]]), OUTLINE, 1.0)
		_text_center(str(i + 1), c + Vector2(0, 16), 11, GOLD)
	# Partitura
	if value is Array:
		_text_center("partitura: " + ScriptContext.to_text(value), Vector2(0, -70), 11, mark if mark.a > 0.0 else CYAN)
	if mark.a > 0.0:
		draw_rect(Rect2(-64, -82, 128, 84), mark, false, 2.0)
