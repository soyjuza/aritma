@tool
## El Faro (capítulo 1, SELECT de varias columnas). Se enciende con el color y el brillo de la tabla faro.
class_name BeaconMachine
extends SqlMachine

const STONE := Color("4a4560")
const STONE_LIGHT := Color("6e6790")
const STONE_DARK := Color("2c2840")
const BRONZE := Color("b48a4e")
const MINI := 2.0
const MINI_ORIGIN := Vector2(-8, -36)
const LIGHTS := {"azul": Color("3fe0ff"), "verde": Color("6be38b"), "dorado": Color("ffd27a"), "morado": Color("c9a0ff")}

var cols := 8
var rows := 8
var lit := 0.0

@onready var _light: PointLight2D = $Luz


func setup(bus: EventBus, data: Dictionary, text: Callable, open_codex: Callable) -> void:
	var board: Dictionary = data.get("board", {})
	cols = int(board.get("cols", 8))
	rows = int(board.get("rows", 8))
	super(bus, data, text, open_codex)


func status_text() -> String:
	return _text.call("beacon_status", {})


func make_tables(_i: int) -> Array:
	var names := LIGHTS.keys()
	return [SqlTable.new("faro", ["nombre", "color", "brillo"], [["Faro del Vórtice", names[_rng.randi() % names.size()], _rng.randi_range(5, 9)]])]


## El cristal toma el color que trajo la consulta.
func react(right: bool) -> void:
	if not right:
		await _wait(0.4)
		return
	var t := create_tween()
	t.tween_property(self, "lit", 1.0, 0.8)
	if _light:
		_light.color = _glow()
		t.parallel().tween_property(_light, "energy", 1.6, 0.8)
	await t.finished


func _glow() -> Color:
	var values := got_values("color")
	return LIGHTS.get(String(values[0]) if not values.is_empty() else "", CYAN)


# ------------------------------------------------------------------ dibujo

func _draw() -> void:
	# El obelisco
	var body := Rect2(-13, -46, 26, 46)
	draw_rect(body.grow(1), OUTLINE)
	draw_rect(body, STONE)
	draw_rect(Rect2(body.position, Vector2(3, body.size.y)), STONE_LIGHT)
	draw_rect(Rect2(body.end.x - 3, body.position.y, 3, body.size.y), STONE_DARK)
	draw_rect(Rect2(-14, -6, 28, 4), BRONZE)
	draw_rect(Rect2(-14, -42, 28, 3), BRONZE)
	# El cristal
	var crystal := PackedVector2Array([Vector2(0, -60), Vector2(6, -51), Vector2(0, -44), Vector2(-6, -51)])
	draw_colored_polygon(crystal, Color("1d3a48").lerp(_glow(), lit))
	draw_polyline(crystal + PackedVector2Array([crystal[0]]), OUTLINE, 1.0)
	draw_line(Vector2(-2, -55), Vector2(0, -57), Color(1, 1, 1, 0.5 + 0.5 * lit), 1.0)
	# Tablero grabado
	var size := Vector2(cols, rows) * MINI
	draw_rect(Rect2(MINI_ORIGIN - Vector2(1, 1) * (MINI + 1), size + Vector2(2, 2) * (MINI + 1)), STONE_DARK.darkened(0.3))
	draw_rect(Rect2(MINI_ORIGIN - Vector2(1, 1), size + Vector2(2, 2)), OUTLINE)
	for y in rows:
		for x in cols:
			draw_rect(Rect2(MINI_ORIGIN + Vector2(x, y) * MINI, Vector2(MINI - 0.5, MINI - 0.5)), STONE_DARK.lerp(CYAN.darkened(0.5), lit))
	_draw_tables({}, -66)
