@tool
## La Consola de la Red (Sala 5): un pedestal de piedra con una esfera de luz. Prueba el
## programa del jugador en dos redes de prueba (ocultas) y en la red de la sala: en cada una
## debe levantar, con puentes.levantar(id), un puente tras otro desde red.inicio hasta
## red.salida (con "shortest" en chambers.json, solo por el camino MÁS CORTO). Mientras
## prueba, la red del abismo muestra cada red de prueba con el camino que encontró el programa.
## Si todo sale bien, la red de la sala queda lista: desde entonces, usar el atril levanta los
## puentes (sin volver a programar) cada vez que haga falta.
class_name NetworkConsole
extends CodeMachine

const OUTLINE := Color("14181c")
const STONE := Color("4a4560")
const STONE_LIGHT := Color("6e6790")
const BRONZE := Color("b48a4e")
const CYAN := Color("3fe0ff")
const GOLD := Color("ffc857")
const GREEN := Color("6be38b")
const RED := Color("ff5a4e")

var real: NetworkRules              # la red de la sala
var tests: Array = []               # redes de prueba
var path: Array = []                # el camino aceptado (la red real)
var show_network: Callable          # (red, camino, bien) -> la muestra en el abismo
var positions: Array = []

var _bus: EventBus
var _data: Dictionary
var _text: Callable
var _rng := RandomNumberGenerator.new()
var _orb := Color("1d3a48")

@onready var _light: PointLight2D = $Luz


func setup(bus: EventBus, data: Dictionary, text: Callable, open_codex: Callable, p_positions: Array, p_show: Callable) -> void:
	_bus = bus
	_data = data
	_text = text
	positions = p_positions
	show_network = p_show
	var seed_value := int(data.get("seed", 0))
	if seed_value != 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()
	view_focus = Vector2(0, -90)
	view_zoom = 1.0
	session.title = String(data.get("name", ""))
	session.file_name = String(data.get("file_name", "red.py"))
	session.code = String(data.get("starter_code", ""))
	session.help = data.get("help", [])
	session.machine = self
	connect_console(open_codex)
	new_networks()


## Red de la sala y redes de prueba nuevas (al empezar y después de cada fallo).
func new_networks() -> void:
	var net: Dictionary = _data.get("network", {})
	var make := func() -> NetworkRules:
		return NetworkRules.make(positions, 0, positions.size() - 1, _rng, float(net.get("reach", 112.0)), float(net.get("keep", 0.55)), int(net.get("min_len", 4)), int(net.get("max_len", 6)), bool(net.get("shortest", false)))
	real = make.call()
	tests = []
	for i in int(net.get("tests", 2)):
		tests.append(make.call())
	path = []
	if show_network.is_valid():
		show_network.call(real, [], true)


func status_text() -> String:
	return _text.call("network_status", {})


# ------------------------------------------------------------------ evaluar (sin dibujar)

func evaluate(source: String, sandbox: ScriptSandbox) -> CodeMachine.Report:
	var report := CodeMachine.Report.new()
	report.success = true
	var all: Array = tests + [real]
	for i in all.size():
		var net: NetworkRules = NetworkRules.new(all[i].positions, all[i].edges, all[i].start, all[i].goal)
		net.require_shortest = all[i].require_shortest
		var result := sandbox.run(source, NetworkAdapter.objects(net, _text), session.max_steps)
		report.output += result.output
		var label: String = _text.call("network_test_label" if i < tests.size() else "network_real_label", {"n": i + 1})
		if not result.ok:
			report.ok = false
			report.success = false
			report.error = "%s: %s" % [label, result.error_text()]
			return report
		var problem := "not_raised" if not net.raised else net.check(net.path)
		report.commands.append({"net": all[i], "path": net.path if typeof(net.path) == TYPE_ARRAY else [], "ok": problem == ""})
		if problem != "":
			report.success = false
			report.message = "%s: %s" % [label, _text.call("network_" + problem, {"len": net.path.size() - 1 if typeof(net.path) == TYPE_ARRAY else 0, "best": net.shortest_path().size() - 1, "start": net.start, "goal": net.goal})]
			break
		if i == all.size() - 1:
			path = net.path.duplicate()
	if report.success:
		report.message = _text.call("network_solved", {})
	return report


# ------------------------------------------------------------------ mostrar

func perform(report: CodeMachine.Report) -> void:
	for step: Dictionary in report.commands:
		show_network.call(step.net, step.path, step.ok)
		_orb = GREEN if step.ok else RED
		_bus.publish(GameEvents.MACHINE_GOOD if step.ok else GameEvents.MACHINE_BAD)
		await _wait(0.9 if step.ok else 1.6)
	if report.success:
		show_network.call(real, [], true)
		_orb = GOLD
		var t := create_tween()
		t.tween_property(_light, "energy", 1.4, 0.4)
		await t.finished
		mark_solved()
	else:
		_orb = Color("1d3a48")
		new_networks()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _draw() -> void:
	var body := Rect2(-11, -30, 22, 30)
	draw_rect(body.grow(1), OUTLINE)
	draw_rect(body, STONE)
	draw_rect(Rect2(body.position, Vector2(3, body.size.y)), STONE_LIGHT)
	draw_rect(Rect2(-12, -6, 24, 3), BRONZE)
	draw_rect(Rect2(-12, -31, 24, 3), BRONZE)
	# La esfera de la consola
	draw_circle(Vector2(0, -38), 7.0, OUTLINE)
	draw_circle(Vector2(0, -38), 6.0, _orb)
	draw_circle(Vector2(-2, -40), 1.5, Color(1, 1, 1, 0.8))
	# Dibujo grabado de una red
	for e in [[Vector2(-6, -22), Vector2(0, -16)], [Vector2(0, -16), Vector2(6, -22)], [Vector2(0, -16), Vector2(0, -9)]]:
		draw_line(e[0], e[1], Color(CYAN, 0.6), 1.0)
	for p in [Vector2(-6, -22), Vector2(6, -22), Vector2(0, -16), Vector2(0, -9)]:
		draw_circle(p, 1.5, CYAN)
