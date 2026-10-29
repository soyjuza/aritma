@tool
## La Bomba de la Cueva (capítulo 3, AND). Llena los tanques que trae la consulta:
## los que tienen poca agua Y la válvula abierta.
class_name PumpMachine
extends SqlMachine

const WATER := Color("3f9fe0")
const TANKS := ["Cuarzo", "Ámbar", "Jade", "Ópalo", "Ónix", "Topacio", "Perla", "Coral"]

var limit := 5
var fill := 0.0    # 0 a 1: cuánto subió el agua de los tanques elegidos


func setup(bus: EventBus, data: Dictionary, text: Callable, open_codex: Callable) -> void:
	limit = int(data.get("limit", 5))
	super(bus, data, text, open_codex)


## Siempre hay uno vacío y abierto, uno vacío pero cerrado y uno lleno y abierto.
func make_tables(_i: int) -> Array:
	var count := _rng.randi_range(4, 5)
	var names := _names(TANKS, count)
	var kinds: Array = [[_rng.randi_range(0, limit - 1), "abierta"], [_rng.randi_range(0, limit - 1), "cerrada"], [_rng.randi_range(limit, 10), "abierta"]]
	while kinds.size() < count:
		kinds.append([_rng.randi_range(0, 10), "abierta" if _rng.randf() < 0.5 else "cerrada"])
	kinds.shuffle()
	var rows: Array = []
	for k in count:
		rows.append([names[k], kinds[k][0], kinds[k][1]])
	return [SqlTable.new("tanques", ["nombre", "nivel", "valvula"], rows)]


func show_round(i: int) -> void:
	super(i)
	fill = 0.0


func react(_right: bool) -> void:
	var t := create_tween()
	t.tween_property(self, "fill", 1.0, 0.7)
	await t.finished


func _draw() -> void:
	var tanks := table("tanques")
	if tanks == null:
		return
	var pumped := got_values("nombre").map(func(v): return SqlEngine.show(v))
	var n := tanks.rows.size()
	for k in n:
		var row: Array = tanks.rows[k]
		var x := -((n - 1) * 22) / 2.0 + k * 22
		var box := Rect2(x - 7, -40, 14, 36)
		draw_rect(box.grow(1), OUTLINE)
		draw_rect(box, Color("1a2230"))
		var level := float(row[1])
		if String(row[0]) in pumped:
			level = lerpf(level, 10.0, fill)
		var h := box.size.y * clampf(level / 10.0, 0.0, 1.0)
		draw_rect(Rect2(box.position.x, box.end.y - h, box.size.x, h), WATER)
		# Válvula: verde abierta, roja cerrada
		draw_circle(Vector2(x, -2), 3.0, OUTLINE)
		draw_circle(Vector2(x, -2), 2.2, GOOD if String(row[2]) == "abierta" else BAD)
	var y := -40.0 + 36.0 * (1.0 - limit / 10.0)
	draw_line(Vector2(-((n - 1) * 22) / 2.0 - 10, y), Vector2(((n - 1) * 22) / 2.0 + 10, y), GOLD, 1.0)
	_draw_tables({"tanques": "nombre"}, -48)
	if mark.a > 0.0:
		draw_rect(Rect2(-((n - 1) * 22) / 2.0 - 12, -44, (n - 1) * 22 + 24, 48), mark, false, 2.0)
