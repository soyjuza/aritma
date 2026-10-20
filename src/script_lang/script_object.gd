## Patrón Adapter: objeto del juego visto desde el Códice.
class_name ScriptObject
extends RefCounted


func type_name() -> String:
	return "objeto"


func describe() -> String:
	return "<%s>" % type_name()


## puerta.abierta
func get_attribute(ctx: ScriptContext, attr: String, line: int) -> Variant:
	ctx.fail(ScriptMessages.text("no_tiene") % [type_name(), attr], line)
	return null


## rojos.periodo = 4
func set_attribute(ctx: ScriptContext, attr: String, _value, line: int) -> void:
	ctx.fail(ScriptMessages.text("no_puede_cambiar") % [attr, type_name()], line)


## puerta.abrir()
func get_method(_attr: String) -> ScriptCallable:
	return null


## rele[2]
func get_index(ctx: ScriptContext, _index, line: int) -> Variant:
	ctx.fail(ScriptMessages.text("no_puede_usar") % type_name(), line)
	return null


## Métodos para la ayuda del Códice.
func help() -> Array:
	return []
