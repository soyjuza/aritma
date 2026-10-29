## Mensajes de error de las consultas (texts.json, "sql_errors").
class_name SqlMessages
extends RefCounted

const PATH := "res://data/texts.json"

static var _messages: Dictionary = {}


## El mensaje key con sus datos: {tabla}, {columna}...
static func text(key: String, params: Dictionary = {}) -> String:
	if _messages.is_empty():
		var file := FileAccess.open(PATH, FileAccess.READ)
		var parsed = JSON.parse_string(file.get_as_text()) if file else null
		_messages = parsed.get("sql_errors", {}) if parsed is Dictionary else {}
	return String(_messages.get(key, key)).format(params)
