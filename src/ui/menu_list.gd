## Lista de opciones con cursor.
class_name MenuList
extends RefCounted

const ROW_H := 52.0

var options: Array
var index := 0
var _enabled: Callable
var _drawn := Rect2()    # dónde se dibujó, para tocar las opciones


func _init(p_options: Array, enabled: Callable = Callable()) -> void:
	options = p_options
	_enabled = enabled


## Mueve el cursor. true si se movió.
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


## Opción bajo un punto de la pantalla, o -1.
func index_at(point: Vector2) -> int:
	if not _drawn.has_point(point):
		return -1
	var i := int((point.y - _drawn.position.y) / ROW_H)
	return i if i < options.size() and is_enabled(i) else -1


## Clic o toque sobre una opción: la elige. true si la tocó.
func clicked(event: InputEventMouse, point: Vector2) -> bool:
	var button := event as InputEventMouseButton
	if button == null or not button.pressed or button.button_index != MOUSE_BUTTON_LEFT:
		return false
	var i := index_at(point)
	if i < 0:
		return false
	index = i
	return true


func draw(ui: UIKit, at: Vector2, width: float) -> void:
	_drawn = Rect2(at, Vector2(width, height()))
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
