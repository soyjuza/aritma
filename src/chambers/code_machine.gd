@tool
## Base de las máquinas de las salas. Patrón Template Method:
## evaluate() corre el código y perform() lo muestra; cada máquina los cambia.
class_name CodeMachine
extends Node2D

signal solved

var session := CodexSession.new()
var view_zoom := 1.0
var view_focus := Vector2.ZERO
var is_solved := false
var locked := false

var _screen: ColorRect
var _time := 0.0


## Resultado de correr el programa en la máquina.
class Report extends RefCounted:
	var ok := true
	var output: Array = []
	var error := ""
	var success := false
	var message := ""
	var commands: Array = []


## Corre el programa con los casos de la sala. No toca nada visible.
func evaluate(_source: String, _sandbox: ScriptSandbox) -> Report:
	return Report.new()


## Muestra en la máquina lo que hizo el programa.
func perform(_report: Report) -> void:
	pass


## Texto mientras trabaja ("Ronda 2 de 3").
func status_text() -> String:
	return ""


## Dónde va la cámara.
func view_center() -> Vector2:
	var visible_width: float = get_viewport_rect().size.x / maxf(get_viewport().get_camera_2d().zoom.x, 0.01)
	return to_global(view_focus) - Vector2(visible_width * 0.235, 0)


func mark_solved() -> void:
	if is_solved:
		return
	is_solved = true
	solved.emit()


## Pantalla del atril.
func show_code(source: String) -> void:
	if _screen and not locked:
		_screen.color = Color("3fe0ff") if source.strip_edges() != "" else Color("1d6f80")


## Bloqueada por la alarma.
func set_locked(on: bool) -> void:
	locked = on
	if _screen:
		if on:
			_screen.color = Color("ff5a4e")
		else:
			show_code(session.code)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	if _screen and locked:
		_screen.modulate.a = 0.45 + 0.55 * absf(sin(_time * 5.0))
	elif _screen and _screen.color == Color("1d6f80"):
		_screen.modulate.a = 0.6 + 0.4 * absf(sin(_time * 2.4))
	elif _screen:
		_screen.modulate.a = 1.0
	queue_redraw()


## Conecta el atril de la escena.
func connect_console(open_codex: Callable) -> void:
	_screen = $Atril/Pantalla
	($Atril/Uso as Interactable).used.connect(open_codex)
