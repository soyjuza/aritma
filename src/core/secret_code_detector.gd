## Detecta el código secreto escrito con el teclado.
class_name SecretCodeDetector
extends RefCounted

var _code: String
var _typed := ""


func _init(code: String) -> void:
	_code = code.to_upper()


## true cuando lo escrito forma el código.
func feed(unicode: int) -> bool:
	if unicode <= 0 or _code == "":
		return false
	_typed = (_typed + char(unicode).to_upper()).right(_code.length())
	if _typed == _code:
		_typed = ""
		return true
	return false
