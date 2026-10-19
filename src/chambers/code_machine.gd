@tool
## Base de las máquinas de las salas: el panel del Códice va EN la máquina. Al usar su atril,
## la cámara la encuadra (la máquina queda en la mitad derecha) y el Códice se abre al
## costado. Al ejecutar, evaluate() corre el programa con los casos de la sala (al instante)
## y devuelve un informe con las órdenes; perform() las muestra en la máquina, una por una.
## PATRÓN TEMPLATE METHOD: CodexState sigue siempre los mismos pasos; cada máquina concreta
## redefine evaluate(), perform() y su dibujo.
## Cada máquina es una escena (scenes/maquinas/) con un «Atril» (atril.tscn) entre sus hijos.
## El script es @tool solo para que su tablero se vea dibujado en el editor.
class_name CodeMachine
extends Node2D

signal solved

var session := CodexSession.new()
var view_zoom := 1.0               # zoom extra mientras se programa (1 = el del juego)
var view_focus := Vector2.ZERO     # punto de la máquina que debe quedar en el centro derecho
var is_solved := false
var locked := false                # hay guardianes despiertos: no acepta código

var _screen: ColorRect
var _time := 0.0


## Resultado de correr el programa en la máquina.
class Report extends RefCounted:
	var ok := true            # el programa corrió sin errores de Python
	var output: Array = []    # lo que imprimió
	var error := ""           # error del programa (si ok es false)
	var success := false      # resolvió la máquina
	var message := ""         # lo que la máquina dice al terminar
	var commands: Array = []  # órdenes para perform()


## Corre el programa con los casos de la sala. No toca nada visible.
func evaluate(_source: String, _sandbox: ScriptSandbox) -> Report:
	return Report.new()


## Muestra en la máquina lo que hizo el programa (espera a que termine la animación).
func perform(_report: Report) -> void:
	pass


## Texto corto mientras la máquina trabaja ("Ronda 2 de 3").
func status_text() -> String:
	return ""


## Dónde poner la cámara para que la máquina quede en la mitad derecha de la pantalla.
func view_center() -> Vector2:
	var visible_width: float = get_viewport_rect().size.x / maxf(get_viewport().get_camera_2d().zoom.x, 0.01)
	return to_global(view_focus) - Vector2(visible_width * 0.235, 0)


func mark_solved() -> void:
	if is_solved:
		return
	is_solved = true
	solved.emit()


## La pantalla del atril se enciende con el código del jugador (o parpadea esperando).
func show_code(source: String) -> void:
	if _screen and not locked:
		_screen.color = Color("3fe0ff") if source.strip_edges() != "" else Color("1d6f80")


## Bloqueada por la alarma: la pantalla del atril late en rojo.
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


## Conecta el atril de la escena (nodo «Atril»): su pantalla muestra el estado del código y
## al usarlo con E se llama a open_codex.
func connect_console(open_codex: Callable) -> void:
	_screen = $Atril/Pantalla
	($Atril/Uso as Interactable).used.connect(open_codex)
