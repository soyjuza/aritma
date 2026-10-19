## Detecta un código secreto escrito con el teclado (modo guía del expositor).
class_name SecretCodeDetector
extends RefCounted

var _code: String
var _typed := ""


func _init(code: String) -> void:
	_code = code.to_upper()


## Devuelve true cuando las últimas letras escritas forman el código.
func feed(unicode: int) -> bool:
	if unicode <= 0 or _code == "":
		return false
	_typed = (_typed + char(unicode).to_upper()).right(_code.length())
	if _typed == _code:
		_typed = ""
		return true
	return false
