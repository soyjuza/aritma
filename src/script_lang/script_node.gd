## Patrón Interpreter: nodo base del árbol. Los bloques tienen otros nodos (Composite).
class_name ScriptNode
extends RefCounted

var line := 0


## Calcula un valor.
func evaluate(_ctx: ScriptContext) -> Variant:
	return null


## Ejecuta una instrucción.
func execute(ctx: ScriptContext) -> void:
	evaluate(ctx)
