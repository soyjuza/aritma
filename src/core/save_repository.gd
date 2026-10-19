## Guarda y carga la partida (sala actual, tiempo restante, caídas).
class_name SaveRepository
extends RefCounted

const PATH := "user://save.cfg"


func exists() -> bool:
	return FileAccess.file_exists(PATH)


func save(snapshot: Dictionary) -> void:
	var file := ConfigFile.new()
	for key in snapshot.keys():
		file.set_value("game", key, snapshot[key])
	file.save(PATH)


func load_snapshot() -> Dictionary:
	var file := ConfigFile.new()
	if file.load(PATH) != OK:
		return {}
	var out := {}
	for key in file.get_section_keys("game"):
		out[key] = file.get_value("game", key)
	return out


func clear() -> void:
	if exists():
		DirAccess.remove_absolute(PATH)
