## Lee los JSON de data/ (configuración, salas y textos).
class_name DataRepository
extends RefCounted

var config: Dictionary
var chambers: Array        # salas del capítulo actual, en orden
var chapters: Array
var chapter := 0
var maps: Dictionary       # mapas del mundo (Raíz, Bosque...)
var town: Dictionary
var texts: Dictionary
var practices: Dictionary
var quests: Dictionary
var touch := false    # en el celular se usan los textos de "touch"
var _all_chambers: Array


func _init(base_path: String = "res://data") -> void:
	config = _read(base_path.path_join("config.json"))
	var chamber_file := _read(base_path.path_join("chambers.json"))
	_all_chambers = chamber_file.get("chambers", [])
	chapters = chamber_file.get("chapters", [])
	maps = chamber_file.get("maps", {})
	use_chapter(0)
	town = chamber_file.get("town", {})
	texts = _read(base_path.path_join("texts.json"))
	practices = _read(base_path.path_join("practices.json"))
	quests = _read(base_path.path_join("quests.json"))


## Modo celular: cambia las líneas que nombran teclas por las de texts.json
## ("touch_chambers" y "touch_talk": número de línea → texto nuevo).
func use_touch() -> void:
	touch = true
	var rooms: Dictionary = texts.get("touch_chambers", {})
	for room in _all_chambers:
		var id := room_id(room)
		if rooms.has(id):
			_replace_lines(room, rooms[id])
	_replace_lines(texts.get("talk", {}), texts.get("touch_talk", {}))


static func _replace_lines(target: Dictionary, changes: Dictionary) -> void:
	for key in changes.keys():
		var lines: Array = target.get(key, [])
		for i in changes[key].keys():
			if int(i) < lines.size():
				lines[int(i)] = changes[key][i]


func setting(key: String, fallback = null):
	return config.get(key, fallback)


## Las salas del capítulo i (chambers.json, "chapters").
func use_chapter(i: int) -> void:
	chapter = i
	if chapters.is_empty():
		chambers = _all_chambers
		return
	use_order(chapters[i].get("chambers", []))
	chapter = i


## Salas en el orden de esta lista de ids. Sin capítulo (chapter = -1) si se llama sola.
func use_order(ids: Array) -> void:
	chapter = -1
	chambers = []
	for id in ids:
		for room in _all_chambers:
			if room_id(room) == id:
				chambers.append(room)


## "id" de la sala; si no tiene, su "kind".
static func room_id(room: Dictionary) -> String:
	return String(room.get("id", room.get("kind", "")))


## Datos del capítulo i ({} si no existe).
func chapter_data(i: int) -> Dictionary:
	return chapters[i] if i >= 0 and i < chapters.size() else {}


## Datos de un mapa del mundo ({} si no existe).
func map_data(id: String) -> Dictionary:
	return maps.get(id, {})


## Mapa donde está la entrada a las salas del capítulo i.
func map_of_chapter(i: int) -> String:
	return String(chapter_data(i).get("map", "pueblo"))


func chapter_name(i: int) -> String:
	return String(chapters[i].get("name", "")) if i < chapters.size() else ""


func chamber_count() -> int:
	return chambers.size()


func chamber_data(index: int) -> Dictionary:
	return chambers[index]


func practice(key: String) -> Dictionary:
	return practices.get(key, {})


func talk(key: String) -> Array:
	return texts.get("talk", {}).get(key, [])


## Mensaje de texts.json con sus {marcadores} reemplazados.
func message(key: String, params: Dictionary = {}) -> String:
	var raw = _raw(key, key)
	if raw is Array:
		raw = " ".join(raw)
	return String(raw).format(params)


func messages(key: String) -> Array:
	var raw = _raw(key, [])
	return raw if raw is Array else [raw]


## Texto de "messages", o su versión táctil si existe.
func _raw(key: String, fallback):
	if touch and texts.get("touch", {}).has(key):
		return texts.touch[key]
	return texts.get("messages", {}).get(key, fallback)


static func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed
	push_error("JSON inválido en " + path)
	return {}
