## Algo que se puede llamar desde un programa del Códice: una función escrita por el
## jugador (def), una función del juego (avanzar, range...) o un método de un objeto.
class_name ScriptCallable
extends RefCounted

var name := ""


## Ejecuta la llamada. Si algo sale mal, deja el error en ctx y devuelve null.
func invoke(_ctx: ScriptContext, _args: Array, _line: int) -> Variant:
	return null
