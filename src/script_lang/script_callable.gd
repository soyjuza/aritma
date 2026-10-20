## Algo que se puede llamar desde el Códice.
class_name ScriptCallable
extends RefCounted

var name := ""


## Si falla deja el error en ctx y devuelve null.
func invoke(_ctx: ScriptContext, _args: Array, _line: int) -> Variant:
	return null
