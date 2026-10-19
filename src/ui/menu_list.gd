## Lista de opciones con cursor, reutilizada por el menú principal y la pausa.
class_name MenuList
extends RefCounted

const ROW_H := 52.0

var options: Array
var index := 0
var _enabled: Callable


func _init(p_options: Array, enabled: Callable = Callable()) -> void:
	options = p_options
	_enabled = enabled


## Mueve el cursor saltando opciones deshabilitadas. Devuelve true si se movió.
func move(actions: Array) -> bool:
	var step := 1 if "ui_down" in actions else (-1 if "ui_up" in actions else 0)
	if step == 0:
		return false
	for i in options.size():
		index = posmod(index + step, options.size())
		if is_enabled(index):
			break
	return true


func is_enabled(i: int) -> bool:
	return not _enabled.is_valid() or _enabled.call(i)


func first_enabled() -> void:
	index = 0
	while not is_enabled(index) and index < options.size() - 1:
		index += 1


func selected() -> String:
	return options[index]


func height() -> float:
	return options.size() * ROW_H


func draw(ui: UIKit, at: Vector2, width: float) -> void:
	for i in options.size():
		var y := at.y + i * ROW_H
		if i == index:
			ui.rect(Rect2(at.x, y, width, ROW_H - 6), Color(UIKit.GOLD, 0.12))
			ui.rect(Rect2(at.x, y, 4, ROW_H - 6), UIKit.CYAN)
			ui.cursor(Vector2(at.x + 16, y + 14))
		var color := UIKit.TEXT if is_enabled(i) else Color(1, 1, 1, 0.25)
		if i == index:
			color = UIKit.GOLD
		ui.text(options[i], Vector2(at.x + 44, y + 8), 26, color, "title")
