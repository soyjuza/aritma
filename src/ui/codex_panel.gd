## Ventana del Códice: editor de código con colores (CodeEdit), ayuda de las funciones de la
## sala y consola de salida. Es una interfaz de controles reales (para poder escribir),
## encima de la vista 3D; CodexState decide cuándo se muestra y qué pasa al ejecutar.
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
var docked := false        # al costado de una máquina (la máquina se ve a la derecha)

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
	_place(help_label, Vector2(0.65, 0.11), Vector2(0.97, 0.80))
	_setup_rich(help_label, _body, 17)
	_place(run_button, Vector2(0.65, 0.83), Vector2(0.97, 0.91))
	run_button.text = "EJECUTAR  (F5)"
	run_button.add_theme_font_override("font", _title)
	run_button.add_theme_font_size_override("font_size", 22)
	run_button.focus_mode = Control.FOCUS_NONE
	run_button.pressed.connect(func(): run_requested.emit())
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


## Pantalla completa (terminales) o al costado izquierdo (máquinas: se ven a la derecha).
func _layout(side: bool) -> void:
	docked = side
	if side:
		_anchor(_shade, Vector2(0, 0), Vector2(0.47, 1))
		_shade.color = Color(0.01, 0.02, 0.03, 0.9)
		_anchor(title_label, Vector2(0.02, 0.03), Vector2(0.45, 0.08))
		_anchor(counter_label, Vector2(0.25, 0.085), Vector2(0.45, 0.12))
		_anchor(editor, Vector2(0.02, 0.12), Vector2(0.45, 0.56))
		_anchor(help_label, Vector2(0.02, 0.57), Vector2(0.45, 0.73))
		_anchor(console, Vector2(0.02, 0.74), Vector2(0.45, 0.88))
		_anchor(run_button, Vector2(0.27, 0.89), Vector2(0.45, 0.94))
		_anchor(footer, Vector2(0.02, 0.95), Vector2(0.45, 0.99))
		title_label.add_theme_font_size_override("font_size", 22)
		help_label.add_theme_font_size_override("normal_font_size", 15)
		help_label.add_theme_font_size_override("bold_font_size", 15)
		run_button.add_theme_font_size_override("font_size", 18)
		footer.add_theme_font_size_override("font_size", 13)
	else:
		_anchor(_shade, Vector2(0, 0), Vector2(1, 1))
		_shade.color = Color(0.01, 0.02, 0.03, 0.82)
		_anchor(title_label, Vector2(0.03, 0.035), Vector2(0.62, 0.09))
		_anchor(counter_label, Vector2(0.45, 0.05), Vector2(0.62, 0.09))
		_anchor(editor, Vector2(0.03, 0.11), Vector2(0.62, 0.68))
		_anchor(console, Vector2(0.03, 0.70), Vector2(0.62, 0.91))
		_anchor(help_label, Vector2(0.65, 0.11), Vector2(0.97, 0.80))
		_anchor(run_button, Vector2(0.65, 0.83), Vector2(0.97, 0.91))
		_anchor(footer, Vector2(0.03, 0.935), Vector2(0.97, 0.98))
		title_label.add_theme_font_size_override("font_size", 28)
		help_label.add_theme_font_size_override("normal_font_size", 17)
		help_label.add_theme_font_size_override("bold_font_size", 17)
		run_button.add_theme_font_size_override("font_size", 22)
		footer.add_theme_font_size_override("font_size", 15)


## Repliega el Códice (mientras la máquina muestra el programa) o lo vuelve a mostrar.
func fold(folded: bool) -> void:
	visible = not folded
	if folded:
		editor.release_focus()
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


func open(session: CodexSession, keys_text: String, side := false) -> void:
	_session = session
	_layout(side)
	title_label.text = ("%s  ·  %s" if side else "EL CÓDICE  ·  %s  ·  %s") % [session.title, session.file_name]
	editor.text = session.code
	console.clear()
	console.append_text("[color=#8d97a8]Escribe tu programa y presiona EJECUTAR.[/color]\n")
	var help := "[color=#e2b44f][b]FUNCIONES DE ESTA SALA[/b][/color]\n" + ("" if side else "\n")
	for entry in session.help:
		if side:
			help += "[color=#4fe3ff]%s[/color]  [color=#8d97a8]%s[/color]\n" % [entry[0], entry[1]]
		else:
			help += "[color=#4fe3ff]%s[/color]\n[color=#8d97a8]%s[/color]\n\n" % [entry[0], entry[1]]
	if not side:
		help += "[color=#8d97a8]Python simplificado: variables, if / elif / else, while, for ... in range(...), def, return, listas, print().[/color]"
	help_label.text = help
	footer.text = keys_text
	_update_counter()
	visible = true
	editor.grab_focus()


func close() -> String:
	visible = false
	editor.release_focus()
	return editor.text


func log_line(text: String, color := "c9d4e2") -> void:
	console.append_text("[color=#%s]%s[/color]\n" % [color, text.replace("[", "[lb]")])


func _update_counter() -> void:
	if _session == null:
		return
	var used := CodexSession.count_lines(editor.text)
	if _session.max_lines > 0:
		counter_label.text = "LÍNEAS %d / %d" % [used, _session.max_lines]
		counter_label.add_theme_color_override("font_color", UIKit.ALERT if used > _session.max_lines else UIKit.CYAN)
	else:
		counter_label.text = "LÍNEAS %d" % used
		counter_label.add_theme_color_override("font_color", UIKit.CYAN)
