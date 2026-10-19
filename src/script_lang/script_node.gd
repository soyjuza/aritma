## PATRÓN INTERPRETER — Nodo abstracto del árbol de un programa del Códice.
## Cada construcción del lenguaje (un número, una suma, un if, un for, una llamada) es un
## nodo que sabe evaluarse o ejecutarse a sí mismo. Los bloques contienen otros nodos
## (patrón Composite), así que un programa entero se ejecuta llamando a execute() en la raíz.
class_name ScriptNode
extends RefCounted

var line := 0


## Expresiones: calcula y devuelve un valor.
func evaluate(_ctx: ScriptContext) -> Variant:
	return null


## Instrucciones: hace algo (por defecto, evalúa la expresión y descarta el resultado).
func execute(ctx: ScriptContext) -> void:
	evaluate(ctx)
