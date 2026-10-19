## PATRÓN ADAPTER (estructural) — Interfaz que el lenguaje del Códice entiende para los
## objetos del juego. Cada adaptador concreto envuelve un objeto real (una puerta, un relé,
## el autómata) y expone solo lo permitido, con nombres en español:
##   puerta.abrir()   rele[2].conexiones   guardian.avanzar(3)
## Así el intérprete no conoce las clases del juego, y el juego no conoce el intérprete.
class_name ScriptObject
extends RefCounted


func type_name() -> String:
	return "objeto"


func describe() -> String:
	return "<%s>" % type_name()


## Atributo: puerta.abierta. Devuelve null y deja un error si no existe.
func get_attribute(ctx: ScriptContext, attr: String, line: int) -> Variant:
	ctx.fail("«%s» no tiene «%s»." % [type_name(), attr], line)
	return null


## Cambiar un atributo: rojos.periodo = 4. Por defecto no se puede.
func set_attribute(ctx: ScriptContext, attr: String, _value, line: int) -> void:
	ctx.fail("«%s» de %s no se puede cambiar." % [attr, type_name()], line)


## Método: puerta.abrir(). Devuelve un ScriptCallable o null.
func get_method(_attr: String) -> ScriptCallable:
	return null


## Índice: rele[2]. Por defecto no se puede indexar.
func get_index(ctx: ScriptContext, _index, line: int) -> Variant:
	ctx.fail("«%s» no se puede usar con [ ]." % type_name(), line)
	return null


## Métodos disponibles, para la ayuda del Códice.
func help() -> Array:
	return []
