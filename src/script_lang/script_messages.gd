## Mensajes de error del Códice (texts.json, "script_errors").
class_name ScriptMessages
extends RefCounted

const PATH := "res://data/texts.json"

static var _messages: Dictionary = {}


static func text(key: String) -> String:
	if _messages.is_empty():
		var file := FileAccess.open(PATH, FileAccess.READ)
		var parsed = JSON.parse_string(file.get_as_text()) if file else null
		_messages = parsed.get("script_errors", {}) if parsed is Dictionary else {}
	return String(_messages.get(key, key))
