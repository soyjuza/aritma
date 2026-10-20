## Lo que una terminal le pasa al Códice cuando el jugador la usa: el título, el archivo,
## el código guardado, el límite de líneas, la ayuda de funciones y cómo crear los objetos
## del juego para cada ejecución. Así el Códice no sabe nada de ninguna cámara en especial.
class_name CodexSession
extends RefCounted

var title := ""
var file_name := "programa.py"
var code := ""
var max_lines := 0                 # 0 = sin límite
var help: Array = []               # [["avanzar(n=1)", "avanza n casillas"], ...]
var api_factory: Callable          # () -> Dictionary con los objetos y funciones del juego
var on_result: Callable            # (ScriptSandbox.Result) -> String: mensaje para la consola
var max_steps := 200000
var close_after_run := false       # cerrar el Códice al ejecutar sin errores (para ver el resultado)
var machine: CodeMachine = null    # si la sesión es de una máquina: ella corre y muestra el programa
var log: Array = []                # lo que mostró la consola (sigue ahí al volver, p. ej. tras pelear)


## Cuántas líneas cuentan para el límite (sin vacías ni comentarios).
static func count_lines(source: String) -> int:
	var n := 0
	for line in source.split("\n"):
		var t := line.strip_edges()
		if t != "" and not t.begins_with("#"):
			n += 1
	return n
