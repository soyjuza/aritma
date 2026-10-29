@tool
## El Mural de los Récords (capítulo 4, ORDER BY y LIMIT). Cada fila del Mural muestra una
## fila de la consulta: los aritmanos con más puntos, del primero al tercero.
class_name MuralMachine
extends SqlMachine

const W := 200.0
const ROW_H := 18.0
const TOP := -112.0
const LEFT := -100.0

const STONE_DARK := Color("27342e")
const STONE := Color("3e5246")
const STONE_LIGHT := Color("6a8070")
const BRONZE := Color("b48a4e")
const BRONZE_DARK := Color("6e5232")
const PLAQUE := Color("1b2226")
const RED := Color("ff5a4e")
const PLAYERS := ["Ada", "Bruno", "Celia", "Dante", "Elsa", "Fabio", "Gala", "Hugo", "Iris", "Joel", "Kira", "Leo"]

var kit: TileKit
var slots := 3

var _rows: Array = []
var _active := -1

@onready var _light: PointLight2D = $Luz


func setup(bus: EventBus, data: Dictionary, text: Callable, open_codex: Callable) -> void:
	slots = int(data.get("slots", 3))
	super(bus, data, text, open_codex)
	view_focus = Vector2(-40, -60)


func status_text() -> String:
	return _text.call("mural_status", {"row": maxi(_active, 0) + 1, "of": _rows.size()})


## 6 aritmanos con puntos distintos.
func make_tables(_i: int) -> Array:
	var names := _names(PLAYERS, 6)
	var points := _distinct(6, 10, 99)
	var rows: Array = []
	for k in 6:
		rows.append([names[k], points[k], _rng.randi_range(8, 14)])
	return [SqlTable.new("aritmanos", ["nombre", "puntos", "edad"], rows)]


func show_round(i: int) -> void:
	super(i)
	_rows.clear()
	for k in slots:
		_rows.append({"result": "", "color": Color("8d97a8"), "lamp": Color("2a3036"), "angle": 0.0})
	_active = -1


## Prueba las filas del Mural una por una.
func react(_right: bool) -> void:
	var count := clampi(got.size(), slots, 6)
	while _rows.size() < count:
		_rows.append({"result": "", "color": Color("8d97a8"), "lamp": Color("2a3036"), "angle": 0.0})
	for k in count:
		_active = k
		var row: Dictionary = _rows[k]
		row.lamp = CYAN
		_bus.publish(GameEvents.MACHINE_STEP)
		var spin := create_tween()
		spin.tween_method(func(a: float): row.angle = a, 0.0, TAU * 1.5, 0.4)
		await spin.finished
		var mine := " · ".join((got[k] as Array).map(func(v): return SqlEngine.show(v))) if k < got.size() else "—"
		var good := " · ".join((wanted[k] as Array).map(func(v): return SqlEngine.show(v))) if k < wanted.size() else "—"
		row.result = mine
		var right := mine == good
		row.color = GOOD if right else RED
		row.lamp = GOLD if right else RED
		_bus.publish(GameEvents.MACHINE_GOOD if right else GameEvents.MACHINE_BAD)
		if not right and kit:
			var sparks := kit.particles(self, _gear_center(k), "Spark", 16, 0.7)
			sparks.emitting = true
			get_tree().create_timer(1.0).timeout.connect(sparks.queue_free)
		await _wait(0.15)
	_active = -1


func mark_solved() -> void:
	if _light:
		var t := create_tween()
		t.tween_property(_light, "energy", 2.0, 0.4)
		t.parallel().tween_property(_light, "color", GOLD, 0.4)
	super()


# ------------------------------------------------------------------ dibujo

func _gear_center(i: int) -> Vector2:
	return Vector2(LEFT + 14, TOP + 18 + i * ROW_H + ROW_H / 2.0)


func _draw() -> void:
	if _rows.is_empty():
		for k in slots:
			_rows.append({"result": "", "color": Color("8d97a8"), "lamp": Color("2a3036"), "angle": 0.0})
	var height := 22 + _rows.size() * ROW_H + 10
	var panel := Rect2(LEFT, TOP, W, height)
	draw_rect(panel.grow(3), OUTLINE)
	draw_rect(panel.grow(2), BRONZE_DARK)
	draw_rect(panel, STONE)
	draw_rect(Rect2(LEFT, TOP, W, 3), STONE_LIGHT)
	draw_rect(Rect2(LEFT - 3, TOP - 6, W + 6, 4), BRONZE)
	_text_center(String(_data.get("mural_title", "")), Vector2(0, TOP + 13), 8, GOLD)
	for i in _rows.size():
		var row: Dictionary = _rows[i]
		var y := TOP + 18 + i * ROW_H
		draw_rect(Rect2(LEFT + 4, y + 1, W - 8, ROW_H - 2), STONE_DARK if i != _active else STONE_DARK.lerp(CYAN, 0.12))
		_gear(_gear_center(i), row.angle, row.lamp)
		draw_rect(Rect2(LEFT + 26, y + 3, 24, ROW_H - 6), PLAQUE)
		_text_center("%dº" % (i + 1), Vector2(LEFT + 38, y + 12.5), 8, BRONZE)
		draw_rect(Rect2(LEFT + 54, y + 3, 132, ROW_H - 6), PLAQUE)
		if row.result != "":
			_text_center(row.result, Vector2(LEFT + 120, y + 12.5), 8, row.color)
		draw_circle(Vector2(LEFT + W - 8, y + ROW_H / 2.0), 3.5, OUTLINE)
		draw_circle(Vector2(LEFT + W - 8, y + ROW_H / 2.0), 2.5, row.lamp)
	# La tabla, a la izquierda del Mural
	var t := table("aritmanos")
	if t:
		var size := TableSign.measure(_font, t.columns, t.rows, 6, t.name)
		TableSign.draw(self, _font, t.columns, t.rows, Vector2(LEFT - 10 - size.x, TOP), 6, t.name)


func _gear(c: Vector2, angle: float, glow: Color) -> void:
	var teeth := 8
	var pts := PackedVector2Array()
	for k in teeth * 2:
		var a := angle + k * PI / teeth
		pts.append(c + Vector2.RIGHT.rotated(a) * (7.0 if k % 2 == 0 else 5.5))
	draw_colored_polygon(pts, BRONZE)
	draw_polyline(pts + PackedVector2Array([pts[0]]), OUTLINE, 1.0)
	draw_circle(c, 2.2, glow)
