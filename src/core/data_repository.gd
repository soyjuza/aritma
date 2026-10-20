## Lee los JSON de data/ (configuración, salas y textos).
class_name DataRepository
extends RefCounted

var config: Dictionary
var chambers: Array
var town: Dictionary
var texts: Dictionary


func _init(base_path: String = "res://data") -> void:
	config = _read(base_path.path_join("config.json"))
	var chamber_file := _read(base_path.path_join("chambers.json"))
	chambers = chamber_file.get("chambers", [])
	town = chamber_file.get("town", {})
	texts = _read(base_path.path_join("texts.json"))


func setting(key: String, fallback = null):
	return config.get(key, fallback)


func chamber_count() -> int:
	return chambers.size()


func chamber_data(index: int) -> Dictionary:
	return chambers[index]


func talk(key: String) -> Array:
	return texts.get("talk", {}).get(key, [])


## Mensaje de texts.json con sus {marcadores} reemplazados.
func message(key: String, params: Dictionary = {}) -> String:
	var raw = texts.get("messages", {}).get(key, key)
	if raw is Array:
		raw = " ".join(raw)
	return String(raw).format(params)


func messages(key: String) -> Array:
	var raw = texts.get("messages", {}).get(key, [])
	return raw if raw is Array else [raw]


static func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed
	push_error("JSON inválido en " + path)
	return {}
