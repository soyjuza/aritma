## Campo de texto de la interfaz dibujada (nombre, código de sala, servidor).
class_name TextField
extends RefCounted

var text := ""
var max_length := 16
var upper := false


func _init(p_text := "", p_max := 16, p_upper := false) -> void:
	text = p_text
	max_length = p_max
	upper = p_upper


## Escribe la tecla. true si la usó (así E o Espacio no cuentan como acciones).
func feed(event: InputEventKey) -> bool:
	if event.keycode == KEY_BACKSPACE:
		text = text.left(-1)
		return true
	if event.keycode == KEY_V and (event.ctrl_pressed or event.meta_pressed):
		_add(DisplayServer.clipboard_get().strip_edges())
		return true
	if event.ctrl_pressed or event.alt_pressed or event.unicode < 32:
		return false
	_add(char(event.unicode))
	return true


func _add(more: String) -> void:
	if upper:
		more = more.to_upper()
	text = (text + more).left(max_length)


func draw(ui: UIKit, r: Rect2, focused: bool, placeholder := "") -> void:
	ui.rect(r, Color(0.02, 0.03, 0.045, 0.95))
	ui.frame(r, UIKit.CYAN if focused else Color("2a3340"), 2.0 if focused else 1.0)
	var shown := text if text != "" else placeholder
	var color := UIKit.TEXT if text != "" else UIKit.MUTED
	# Si no cabe, se ve el final
	while shown.length() > 1 and ui.measure(shown, 22) > r.size.x - 34:
		shown = shown.substr(1)
	ui.text(shown, r.position + Vector2(12, (r.size.y - 26) / 2.0), 22, color, "body", false)
	if focused and ui.blink(2.0):
		var x := r.position.x + 14 + (ui.measure(shown, 22) if text != "" else 0.0)
		ui.rect(Rect2(x, r.position.y + 8, 2, r.size.y - 16), UIKit.CYAN)
