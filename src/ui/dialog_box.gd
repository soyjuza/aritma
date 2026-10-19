## Cuadro de diálogo con efecto de máquina de escribir.
## Si un texto empieza con "NOMBRE: ", el nombre se muestra en una placa aparte.
## Divide los textos en páginas de 3 líneas y ejecuta un callback al cerrarse.
class_name DialogBox
extends RefCounted

const LINES_PER_PAGE := 3
const FONT_SIZE := 26
const BOX_W := 1080.0
const BOX_H := 170.0

var _bus: EventBus
var _ui: UIKit
var _pages: Array = []      # [{speaker, lines}]
var _page := 0
var _shown := 0.0
var _on_done: Array[Callable] = []


func _init(bus: EventBus, ui: UIKit) -> void:
	_bus = bus
	_ui = ui


func is_open() -> bool:
	return not _pages.is_empty()


## Agrega textos. Si ya hay un diálogo abierto, se encolan al final.
func say(texts: Array, on_done: Callable = Callable()) -> void:
	for t in texts:
		var raw := String(t)
		var speaker := ""
		var colon := raw.find(": ")
		if colon > 0 and colon < 22 and raw.substr(0, colon) == raw.substr(0, colon).to_upper():
			speaker = raw.substr(0, colon)
			raw = raw.substr(colon + 2)
		var lines := _ui.wrap(raw, BOX_W - 80.0, FONT_SIZE)
		for i in range(0, lines.size(), LINES_PER_PAGE):
			_pages.append({"speaker": speaker, "lines": lines.slice(i, i + LINES_PER_PAGE)})
	if on_done.is_valid():
		_on_done.append(on_done)


func close() -> void:
	_pages = []
	_page = 0
	_shown = 0.0
	_on_done = []


func update(delta: float, chars_per_second: float) -> void:
	if not is_open():
		return
	var before := int(_shown)
	_shown = min(_shown + delta * chars_per_second, _page_length())
	if int(_shown) != before and int(_shown) % 3 == 0 and chars_per_second < 500.0:
		_bus.publish(GameEvents.DIALOG_CHAR)


func advance() -> void:
	if not is_open():
		return
	if int(_shown) < _page_length():
		_shown = _page_length()
		return
	_page += 1
	_shown = 0.0
	_bus.publish(GameEvents.MENU_MOVE)
	if _page >= _pages.size():
		var callbacks := _on_done
		close()
		for callback in callbacks:
			callback.call()


func draw(ui: UIKit) -> void:
	if not is_open():
		return
	var s := ui.size()
	var w := minf(BOX_W, s.x - 40.0)
	var r := Rect2((s.x - w) / 2.0, s.y - BOX_H - 24.0, w, BOX_H)
	ui.panel(r)
	var page: Dictionary = _pages[_page]
	if page.speaker != "":
		var nw := ui.measure(page.speaker, 22, "title") + 40.0
		var plate := Rect2(r.position + Vector2(28, -22), Vector2(nw, 40))
		ui.panel(plate, UIKit.PANEL_LIGHT)
		ui.text(page.speaker, plate.position + Vector2(20, 8), 22, UIKit.GOLD, "title")
	var remaining := int(_shown)
	for i in page.lines.size():
		var line_text := String(page.lines[i])
		ui.text(line_text.substr(0, clampi(remaining, 0, line_text.length())), r.position + Vector2(40, 30 + i * 40), FONT_SIZE)
		remaining -= line_text.length()
	if int(_shown) >= _page_length() and ui.blink(2.5):
		ui.more_arrow(r.end - Vector2(44, 34))


func _page_length() -> int:
	var total := 0
	for line_text in _pages[_page].lines:
		total += String(line_text).length()
	return total
