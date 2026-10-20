@tool
## El Faro (Sala 3). Enciende el tablero con luces.encender().
class_name BeaconMachine
extends CodeMachine

const OUTLINE := Color("14181c")
const STONE := Color("4a4560")
const STONE_LIGHT := Color("6e6790")
const STONE_DARK := Color("2c2840")
const BRONZE := Color("b48a4e")
const CYAN := Color("3fe0ff")
const MINI := 2.0
const MINI_ORIGIN := Vector2(-8, -36)

var cols := 8
var rows := 8
var lit := 0.0

var _bus: EventBus
var _text: Callable

@onready var _light: PointLight2D = $Luz


func setup(bus: EventBus, data: Dictionary, text: Callable, open_codex: Callable) -> void:
	_bus = bus
	_text = text
	var board: Dictionary = data.get("board", {})
	cols = int(board.get("cols", 8))
	rows = int(board.get("rows", 8))
	view_focus = Vector2(0, -30)
	session.title = String(data.get("name", ""))
	session.file_name = String(data.get("file_name", "faro.py"))
	session.code = String(data.get("starter_code", ""))
	session.help = data.get("help", [])
	session.machine = self
	connect_console(open_codex)


func status_text() -> String:
	return _text.call("beacon_status", {})


# ------------------------------------------------------------------ evaluar (sin dibujar)

func evaluate(source: String, sandbox: ScriptSandbox) -> CodeMachine.Report:
	var report := CodeMachine.Report.new()
	var wanted := [false]
	var api := {"luces": LightsAdapter.new(func(): wanted[0] = true, func(): return wanted[0], func(): wanted[0] = false)}
	var result := sandbox.run(source, api, session.max_steps)
	report.output = result.output
	report.ok = result.ok
	report.error = result.error_text() if not result.ok else ""
	report.success = result.ok and wanted[0]
	report.message = _text.call("beacon_solved" if report.success else "beacon_still_dark", {})
	return report


# ------------------------------------------------------------------ mostrar

func perform(report: CodeMachine.Report) -> void:
	if not report.success:
		_bus.publish(GameEvents.MACHINE_BAD)
		return
	_bus.publish(GameEvents.MACHINE_ROUND)
	var t := create_tween()
	t.tween_property(self, "lit", 1.0, 0.8)
	t.parallel().tween_property(_light, "energy", 1.6, 0.8)
	await t.finished
	mark_solved()


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
	draw_colored_polygon(crystal, Color("1d3a48").lerp(CYAN, lit))
	draw_polyline(crystal + PackedVector2Array([crystal[0]]), OUTLINE, 1.0)
	draw_line(Vector2(-2, -55), Vector2(0, -57), Color(1, 1, 1, 0.5 + 0.5 * lit), 1.0)
	# Tablero grabado
	var size := Vector2(cols, rows) * MINI
	draw_rect(Rect2(MINI_ORIGIN - Vector2(1, 1) * (MINI + 1), size + Vector2(2, 2) * (MINI + 1)), STONE_DARK.darkened(0.3))
	draw_rect(Rect2(MINI_ORIGIN - Vector2(1, 1), size + Vector2(2, 2)), OUTLINE)
	for y in rows:
		for x in cols:
			draw_rect(Rect2(MINI_ORIGIN + Vector2(x, y) * MINI, Vector2(MINI - 0.5, MINI - 0.5)), STONE_DARK.lerp(CYAN.darkened(0.5), lit))
