## Puntos de habilidad: se ganan con misiones y jefes y se gastan en la pausa.
class_name SkillTree
extends RefCounted

var list: Array      # config.json "skills"
var levels := {}     # id → nivel
var earned := 0


func _init(p_list: Array) -> void:
	list = p_list


func skill(id: String) -> Dictionary:
	for s in list:
		if s.id == id:
			return s
	return {}


func level(id: String) -> int:
	return int(levels.get(id, 0))


func max_level(id: String) -> int:
	return int(skill(id).get("max", 1))


func free_points() -> int:
	var spent := 0
	for id in levels:
		spent += int(levels[id])
	return earned - spent


func can_raise(id: String) -> bool:
	return free_points() > 0 and level(id) < max_level(id)


func raise(id: String) -> bool:
	if not can_raise(id):
		return false
	levels[id] = level(id) + 1
	return true


func grant(points: int) -> void:
	earned += points


func reset() -> void:
	levels.clear()
	earned = 0


func save_state() -> Dictionary:
	return {"levels": levels.duplicate(), "earned": earned}


func restore(data: Dictionary) -> void:
	levels = (data.get("levels", {}) as Dictionary).duplicate()
	earned = int(data.get("earned", 0))
