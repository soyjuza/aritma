## Ventana del Códice: editor, ayuda y consola.
class_name CodexPanel
extends Control

signal run_requested

const KEYWORDS := ["if", "elif", "else", "while", "for", "in", "def", "return", "break", "continue", "pass", "and", "or", "not", "True", "False", "None"]
const BUILTINS := ["range", "len", "print", "decir", "abs", "min", "max", "int", "str", "bin", "sum", "round", "sorted"]

var editor := CodeEdit.new()
var title_label := Label.new()
var counter_label := Label.new()
var help_label := RichTextLabel.new()
var console := RichTextLabel.new()
var run_button := Button.new()
var footer := Label.new()
var board := BlockBoard.new()
var mode_button := Button.new()
var docked := false
var zoom := 1.0     # en el celular todo el Códice se ve más grande

var _shade := ColorRect.new()

var _mono: Font
var _body: Font
var _title: Font


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_mono = load("res://assets/fonts/JetBrainsMono.ttf")
	_body = load(UIKit.PIXEL_FONT)
	_title = load(UIKit.PIXEL_FONT)
	_shade.color = Color(0.01, 0.02, 0.03, 0.82)
	_shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_shade)
	_place(title_label, Vector2(0.03, 0.035), Vector2(0.62, 0.09))
	title_label.add_theme_font_override("font", _title)
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", UIKit.GOLD)
	_place(counter_label, Vector2(0.45, 0.05), Vector2(0.62, 0.09))
	counter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	counter_label.add_theme_font_override("font", _mono)
	counter_label.add_theme_font_size_override("font_size", 16)
	_place(editor, Vector2(0.03, 0.11), Vector2(0.62, 0.68))
	_setup_editor()
	_place(console, Vector2(0.03, 0.70), Vector2(0.62, 0.91))
	_setup_rich(console, _mono, 16)
	_place(help_label, Vector2(0.65, 0.11), Vector2(0.97, 0.72))
	_setup_rich(help_label, _body, 17)
	help_label.scroll_following = false
	_place(run_button, Vector2(0.65, 0.83), Vector2(0.97, 0.91))
	run_button.add_theme_font_override("font", _title)
	run_button.add_theme_font_size_override("font_size", 22)
	run_button.focus_mode = Control.FOCUS_NONE
	run_button.pressed.connect(func(): run_requested.emit())
	_place(board, Vector2(0.03, 0.11), Vector2(0.62, 0.68))
	board.changed.connect(_update_counter)
	_place(mode_button, Vector2(0.65, 0.74), Vector2(0.97, 0.81))
	mode_button.add_theme_font_override("font", _title)
	mode_button.add_theme_font_size_override("font_size", 18)
	mode_button.focus_mode = Control.FOCUS_NONE
	mode_button.pressed.connect(toggle_mode)
	_place(footer, Vector2(0.03, 0.935), Vector2(0.97, 0.98))
	footer.add_theme_font_override("font", _body)
	footer.add_theme_font_size_override("font_size", 15)
	footer.add_theme_color_override("font_color", UIKit.MUTED)
	visible = false


func _place(control: Control, from: Vector2, to: Vector2) -> void:
	_anchor(control, from, to)
	add_child(control)


func _anchor(control: Control, from: Vector2, to: Vector2) -> void:
	control.anchor_left = from.x
	control.anchor_top = from.y
	control.anchor_right = to.x
	control.anchor_bottom = to.y


## Agranda el Códice: dibuja en un lienzo más chico y lo escala.
func _fit() -> void:
	if zoom == 1.0:
		return
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	position = Vector2.ZERO
	scale = Vector2(zoom, zoom)
	size = get_viewport_rect().size / zoom
	if not get_viewport().size_changed.is_connected(_fit):
		get_viewport().size_changed.connect(_fit)


## Pantalla completa o al costado de la máquina.
func _layout(side: bool) -> void:
	docked = side
	if side:
		_anchor(_shade, Vector2(0, 0), Vector2(0.47, 1))
		_shade.color = Color(0.01, 0.02, 0.03, 0.9)
		_anchor(title_label, Vector2(0.02, 0.03), Vector2(0.45, 0.08))
		_anchor(counter_label, Vector2(0.25, 0.085), Vector2(0.45, 0.12))
		_anchor(editor, Vector2(0.02, 0.12), Vector2(0.45, 0.52))
		_anchor(help_label, Vector2(0.02, 0.53), Vector2(0.45, 0.73))
		_anchor(console, Vector2(0.02, 0.74), Vector2(0.45, 0.88))
		_anchor(run_button, Vector2(0.27, 0.89), Vector2(0.45, 0.94))
		_anchor(mode_button, Vector2(0.02, 0.89), Vector2(0.25, 0.94))
		_anchor(board, Vector2(0.02, 0.12), Vector2(0.45, 0.73))
		_anchor(footer, Vector2(0.02, 0.95), Vector2(0.45, 0.99))
		title_label.add_theme_font_size_override("font_size", 22)
		help_label.add_theme_font_size_override("normal_font_size", 14)
		help_label.add_theme_font_size_override("bold_font_size", 14)
		run_button.add_theme_font_size_override("font_size", 18)
		footer.add_theme_font_size_override("font_size", 13)
	else:
		_anchor(_shade, Vector2(0, 0), Vector2(1, 1))
		_shade.color = Color(0.01, 0.02, 0.03, 0.82)
		_anchor(title_label, Vector2(0.03, 0.035), Vector2(0.62, 0.09))
		_anchor(counter_label, Vector2(0.45, 0.05), Vector2(0.62, 0.09))
		_anchor(editor, Vector2(0.03, 0.11), Vector2(0.62, 0.68))
		_anchor(console, Vector2(0.03, 0.70), Vector2(0.62, 0.91))
		_anchor(help_label, Vector2(0.65, 0.11), Vector2(0.97, 0.72))
		_anchor(run_button, Vector2(0.65, 0.83), Vector2(0.97, 0.91))
		_anchor(mode_button, Vector2(0.65, 0.74), Vector2(0.97, 0.81))
		_anchor(board, Vector2(0.03, 0.11), Vector2(0.62, 0.68))
		_anchor(footer, Vector2(0.03, 0.935), Vector2(0.97, 0.98))
		title_label.add_theme_font_size_override("font_size", 28)
		help_label.add_theme_font_size_override("normal_font_size", 17)
		help_label.add_theme_font_size_override("bold_font_size", 17)
		run_button.add_theme_font_size_override("font_size", 22)
		footer.add_theme_font_size_override("font_size", 15)
		if zoom != 1.0:
			# Deja libre la esquina del botón táctil CERRAR
			_anchor(counter_label, Vector2(0.65, 0.05), Vector2(0.97, 0.09))
			_anchor(title_label, Vector2(0.03, 0.035), Vector2(0.64, 0.09))
			_anchor(mode_button, Vector2(0.65, 0.74), Vector2(0.88, 0.81))
			_anchor(run_button, Vector2(0.65, 0.83), Vector2(0.88, 0.91))


## Esconde o muestra el Códice.
func fold(folded: bool) -> void:
	visible = not folded
	if folded:
		editor.release_focus()
		board.release_focus()
	else:
		_focus()


func _focus() -> void:
	if _blocks_on():
		board.grab_focus()
	else:
		editor.grab_focus()


func _setup_editor() -> void:
	editor.add_theme_font_override("font", _mono)
	editor.add_theme_font_size_override("font_size", 19)
	editor.add_theme_color_override("background_color", Color("090d12"))
	editor.add_theme_color_override("font_color", Color("ece4d0"))
	editor.add_theme_color_override("caret_color", UIKit.CYAN)
	editor.add_theme_color_override("current_line_color", Color(0.31, 0.89, 1.0, 0.07))
	editor.add_theme_color_override("line_number_color", Color("3e4a58"))
	editor.gutters_draw_line_numbers = true
	editor.indent_automatic = true
	editor.indent_size = 4
	editor.indent_use_spaces = true
	editor.auto_brace_completion_enabled = true
	editor.highlight_current_line = true
	editor.scroll_smooth = true
	var hl := CodeHighlighter.new()
	hl.number_color = Color("c79bff")
	hl.symbol_color = Color("8d97a8")
	hl.function_color = UIKit.CYAN
	hl.member_variable_color = Color("e2b44f")
	for word in KEYWORDS:
		hl.add_keyword_color(word, Color("ff9a6b"))
	for word in BUILTINS:
		hl.add_keyword_color(word, Color("e2b44f"))
	hl.add_color_region("#", "", Color("6b7a8c"), true)
	hl.add_color_region("\"", "\"", Color("a6e3a1"))
	hl.add_color_region("'", "'", Color("a6e3a1"))
	editor.syntax_highlighter = hl
	editor.text_changed.connect(_update_counter)


func _setup_rich(label: RichTextLabel, font: Font, size: int) -> void:
	label.bbcode_enabled = true
	label.scroll_following = true
	label.add_theme_font_override("normal_font", font)
	label.add_theme_font_override("bold_font", font)
	label.add_theme_font_size_override("normal_font_size", size)
	label.add_theme_font_size_override("bold_font_size", size)
	label.add_theme_color_override("default_color", Color("c9d4e2"))
	var style := StyleBoxFlat.new()
	style.bg_color = Color("0b1016")
	style.border_color = Color("1f4b57")
	style.set_border_width_all(1)
	style.set_content_margin_all(12)
	label.add_theme_stylebox_override("normal", style)


var _session: CodexSession
var text: Callable


func _t(key: String, params: Dictionary = {}) -> String:
	return String(text.call(key, params)) if text.is_valid() else key


func open(session: CodexSession, keys_text: String, side := false) -> void:
	_session = session
	_fit()
	# En el celular no cabe al costado: pantalla completa
	side = side and zoom == 1.0
	_layout(side)
	run_button.text = _t("codex_run_button")
	title_label.text = _t("codex_title_side" if side or zoom != 1.0 else "codex_title", {"title": session.title, "file": session.file_name})
	editor.text = session.code
	board.session = session
	board.hint = _piece_help
	board.texts = {"program": _t("blocks_program"), "tray": _t("blocks_tray"), "empty": _t("blocks_empty"), "tray_empty": _t("blocks_tray_empty"), "keys": _t("blocks_keys")}
	console.clear()
	console.append_text("[color=#8d97a8]%s[/color]\n" % _t("codex_welcome" if session.blocks.is_empty() else "codex_welcome_blocks"))
	if not session.blocks.is_empty():
		for line in session.goal:
			console.append_text("[color=#e2b44f]%s[/color]\n" % line.replace("[", "[lb]"))
	# Lo que tenía la consola antes
	for line in session.log:
		console.append_text(line)
	var help := "[color=#e2b44f][b]%s[/b][/color]\n" % _t("codex_help_title") + ("" if side else "\n")
	for entry in session.help:
		if side:
			help += "[color=#4fe3ff]%s[/color]  [color=#8d97a8]%s[/color]\n" % [entry[0], entry[1]]
		else:
			help += "[color=#4fe3ff]%s[/color]\n[color=#8d97a8]%s[/color]\n\n" % [entry[0], entry[1]]
	if not side:
		help += "[color=#8d97a8]%s[/color]" % _t("codex_language")
	help_label.text = help
	footer.text = keys_text
	show_mode()
	visible = true
	_focus()


func close() -> String:
	visible = false
	editor.release_focus()
	board.release_focus()
	return source()


## El programa que se va a correr.
func source() -> String:
	return _session.blocks_source() if _blocks_on() else editor.text


## Escribe en el editor de texto (lo usan las pruebas).
func write(code: String) -> void:
	if _session:
		_session.use_blocks = false
	editor.text = code
	show_mode()


## Cambia entre bloques y escribir a mano.
func toggle_mode() -> void:
	if _session == null or _session.blocks.is_empty():
		return
	if _blocks_on() and not _session.placed.is_empty():
		editor.text = _session.blocks_source()
	_session.use_blocks = not _session.use_blocks
	show_mode()
	_focus()


func _blocks_on() -> bool:
	return _session != null and _session.use_blocks and not _session.blocks.is_empty()


func show_mode() -> void:
	var blocks := _blocks_on()
	board.visible = blocks
	editor.visible = not blocks
	help_label.visible = not (blocks and docked)
	mode_button.visible = _session != null and not _session.blocks.is_empty()
	mode_button.text = _t("blocks_to_text" if blocks else "blocks_to_blocks")
	_update_counter()


## Ayuda de una pieza, sacada de la lista de funciones de la sala.
func _piece_help(piece: String) -> String:
	for entry in _session.help:
		var name := String(entry[0]).split("(")[0].strip_edges()
		if name != "" and piece.contains(name):
			return "%s: %s" % [entry[0], entry[1]]
	return ""


func log_line(text: String, color := "c9d4e2") -> void:
	var line := "[color=#%s]%s[/color]\n" % [color, text.replace("[", "[lb]")]
	console.append_text(line)
	if _session:
		_session.log.append(line)
		if _session.log.size() > 80:
			_session.log.pop_front()


func _update_counter() -> void:
	if _session == null:
		return
	var used := CodexSession.count_lines(source())
	if _session.max_lines > 0:
		counter_label.text = _t("codex_lines_max", {"used": used, "max": _session.max_lines})
		counter_label.add_theme_color_override("font_color", UIKit.ALERT if used > _session.max_lines else UIKit.CYAN)
	else:
		counter_label.text = _t("codex_lines", {"used": used})
		counter_label.add_theme_color_override("font_color", UIKit.CYAN)
