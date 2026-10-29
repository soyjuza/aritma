@tool
## Puerta del templo (pueblo): se abre al leer su palabra con SELECT * FROM puerta.
class_name GateMachine
extends SqlMachine

var gate_open := false

var _open_fn: Callable


## Lo que hace la puerta al abrirse (lo pone el pueblo).
func on_open(open_fn: Callable) -> void:
	_open_fn = open_fn


func setup(bus: EventBus, data: Dictionary, text: Callable, open_codex: Callable) -> void:
	super(bus, data, text, open_codex)
	view_focus = Vector2(-28, -24)


func status_text() -> String:
	return _text.call("gate_status", {})


func make_tables(_i: int) -> Array:
	return [SqlTable.new("puerta", ["palabra", "forma"], [["ábrete", "arco"]])]


func react(right: bool) -> void:
	if right and not gate_open:
		gate_open = true
		if _open_fn.is_valid():
			await _open_fn.call()
	else:
		await _wait(0.4)


func mark_solved() -> void:
	gate_open = true
	super()
