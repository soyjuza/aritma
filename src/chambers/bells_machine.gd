@tool
## Las Campanas de la Cima (capítulo 5, JOIN). La partitura nombra las campanas y la tabla
## campanas dice qué número tiene cada una: hay que juntarlas para saber cuáles tocar.
class_name BellsMachine
extends SqlMachine

const BRONZE := Color("d8a25a")
const NAMES := ["Sol", "Luna", "Río", "Nube", "Viento"]

var bells := 5
var ringing := -1    # la campana que suena ahora


func setup(bus: EventBus, data: Dictionary, text: Callable, open_codex: Callable) -> void:
	bells = int(data.get("bells", 5))
	super(bus, data, text, open_codex)


## Cada ronda: las campanas con números nuevos y una partitura de 3 o 4 notas.
func make_tables(_i: int) -> Array:
	var names := NAMES.slice(0, bells)
	var numbers := range(1, bells + 1)
	numbers.shuffle()
	var catalog: Array = []
	for k in bells:
		catalog.append([names[k], numbers[k]])
	var song: Array = []
	for k in _rng.randi_range(3, 4):
		song.append([k + 1, names[_rng.randi() % names.size()]])
	return [SqlTable.new("partitura", ["orden", "campana"], song), SqlTable.new("campanas", ["nombre", "numero"], catalog)]


func show_round(i: int) -> void:
	super(i)
	ringing = -1


## Suenan una por una, en el orden de la consulta.
func react(_right: bool) -> void:
	for value in got_values("numero"):
		ringing = int(value) if SqlEngine.is_number(value) else -1
		_bus.publish(GameEvents.MACHINE_STEP)
		await _wait(0.35)
	ringing = -1


func _draw() -> void:
	draw_rect(Rect2(-60, -62, 120, 5).grow(1), OUTLINE)
	draw_rect(Rect2(-60, -62, 120, 5), WOOD)
	for i in bells:
		var x := -48 + i * 24
		var on := ringing == i + 1
		var swing := sin(Time.get_ticks_msec() / 120.0 + i) * 3.0 if on else 0.0
		var top := Vector2(x, -57)
		draw_line(top, top + Vector2(swing, 8), OUTLINE, 1.0)
		var c := top + Vector2(swing, 18)
		var bell := PackedVector2Array([c + Vector2(-5, -10), c + Vector2(5, -10), c + Vector2(9, 4), c + Vector2(-9, 4)])
		draw_colored_polygon(bell, BRONZE.lightened(0.35) if on else BRONZE)
		draw_polyline(bell + PackedVector2Array([bell[0]]), OUTLINE, 1.0)
		_text_center(str(i + 1), c + Vector2(0, 14), 6, GOLD)
	_draw_tables({"campanas": "numero"}, -70)
	if mark.a > 0.0:
		draw_rect(Rect2(-64, -66, 128, 68), mark, false, 2.0)
