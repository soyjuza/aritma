## Misiones secundarias (data/quests.json): estado, objetos hallados y recompensas.
class_name QuestLog
extends RefCounted

var states := {}     # id → "active" o "done"
var found := {}      # objeto → id de su misión
var main: Dictionary
var list: Array

var _game: Game
var _problems: Dictionary = {}
var _rng := RandomNumberGenerator.new()


func _init(game: Game, data: Dictionary) -> void:
	_game = game
	main = data.get("main", {})
	list = data.get("quests", [])
	_rng.randomize()
	for q in list:
		if q.get("kind", "") == "quiz":
			_problems[q.id] = BossQuiz.new(_game.data.message, {q.problem: q.get("settings", {})})


func quest(id: String) -> Dictionary:
	for q in list:
		if q.id == id:
			return q
	return {}


func state(id: String) -> String:
	return String(states.get(id, ""))


func reset() -> void:
	states.clear()
	found.clear()


## Cuántos objetos de la misión id ya se recogieron.
func found_count(id: String) -> int:
	return found.values().count(id)


## Cuántas misiones están cumplidas.
func done_count() -> int:
	return list.filter(func(q): return state(q.id) == "done").size()


## Hablar con quien da la misión.
func talk(id: String) -> void:
	var q := quest(id)
	if state(id) == "done":
		_game.dialog.say(q.get("thanks", []))
	elif state(id) == "":
		_game.dialog.say(q.get("offer", []), func(): _start(id))
	elif q.kind == "quiz":
		_game.dialog.say(q.get("again", []), func(): _ask(id, 0))
	else:
		var lines: Array = q.get("progress", [])
		_game.dialog.say(lines.map(func(l): return String(l).format({"n": found_count(id), "of": int(q.count)})))


func _start(id: String) -> void:
	var q := quest(id)
	states[id] = "active"
	_game.notify([_game.data.message("quest_new", {"title": q.title})], 4.0, true)
	if q.kind == "quiz":
		_ask(id, 0)
	elif found_count(id) >= int(q.count):
		_complete(id)


## La pregunta n de la misión. Sin prisa: falla y se vuelve a hablar.
func _ask(id: String, n: int) -> void:
	var q := quest(id)
	var quiz: Dictionary = (_problems[id] as BossQuiz).make(q.problem, _rng)
	quiz.header = _game.data.message("quest_quiz_header", {"title": q.title, "n": n + 1, "of": int(q.count)})
	quiz.calm = true
	_game.machine.change("quiz", {"quiz": quiz, "seconds": float(q.get("seconds", 60)), "on_done": func(right): _answered(id, n, right)})


func _answered(id: String, n: int, right: bool) -> void:
	var q := quest(id)
	if not right:
		_game.dialog.say(q.get("fail", []))
	elif n + 1 < int(q.count):
		_ask(id, n + 1)
	else:
		_complete(id)


## Tala recoge un objeto (un engranaje).
func pick(item: String, id: String) -> void:
	if found.has(item):
		return
	found[item] = id
	var q := quest(id)
	_game.notify([_game.data.message("quest_item", {"item": q.get("item", ""), "n": found_count(id), "of": int(q.count)})], 3.0, true)
	if found_count(id) >= int(q.count) and state(id) != "done":
		_complete(id)


func _complete(id: String) -> void:
	var q := quest(id)
	states[id] = "done"
	_game.dialog.say(q.get("done", []))
	_game.notify([_game.data.message("quest_done", {"title": q.title})], 5.0, true)
	_game.grant_points(int(q.get("points", 1)))


func save_state() -> Dictionary:
	return {"states": states.duplicate(), "found": found.duplicate()}


func restore(data: Dictionary) -> void:
	states = (data.get("states", {}) as Dictionary).duplicate()
	found = (data.get("found", {}) as Dictionary).duplicate()
