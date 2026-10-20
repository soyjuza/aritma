@tool
## La Mesa de las Figuras (Sala 4). Emite solved al terminar.
class_name FigureTable
extends Node2D

signal solved

const OUTLINE := Color("14181c")
const STONE := Color("5b4a42")
const STONE_LIGHT := Color("85705f")
const STONE_DARK := Color("3a2e29")
const BRONZE := Color("b48a4e")
const BRONZE_DARK := Color("6e5232")
const CYAN := Color("3fe0ff")
const GOLD := Color("ffc857")
const SLAB := Rect2(-60, -92, 120, 84)
const MINI := 13.0

var puzzles: Array = []
var current := 0
var is_solved := false
var glow := 0.0

var _time := 0.0
var _font: Font = load(UIKit.PIXEL_FONT)

@onready var _light: PointLight2D = $Luz


func setup(data: Dictionary, rng: RandomNumberGenerator, open_puzzle: Callable) -> void:
	puzzles.clear()
	for p in data.get("puzzles", []):
		puzzles.append(FigurePuzzle.from_layout(p.get("rows", []), String(p.get("title", "")), bool(p.get("turned", false)), rng))
	current = 0
	($Atril/Uso as Interactable).prompt_key = "prompt_figures"
	($Atril/Uso as Interactable).used.connect(open_puzzle)


func puzzle() -> FigurePuzzle:
	return puzzles[mini(current, puzzles.size() - 1)]


## Siguiente rompecabezas. true si ya no quedan.
func advance() -> bool:
	current += 1
	if current < puzzles.size():
		return false
	current = puzzles.size() - 1
	is_solved = true
	var t := create_tween()
	t.tween_property(self, "glow", 1.0, 0.8)
	t.parallel().tween_property(_light, "energy", 1.8, 0.8)
	t.parallel().tween_property(_light, "color", GOLD, 0.8)
	solved.emit()
	return true


func _process(delta: float) -> void:
	_time += delta
	if not Engine.is_editor_hint() and has_node("Atril/Pantalla"):
		var screen: ColorRect = $Atril/Pantalla
		screen.color = GOLD if is_solved else Color("3fe0ff")
		screen.modulate.a = 1.0 if is_solved else 0.6 + 0.4 * absf(sin(_time * 2.4))
	queue_redraw()


# ------------------------------------------------------------------ dibujo

func _draw() -> void:
	# Losa
	draw_rect(SLAB.grow(3), OUTLINE)
	draw_rect(SLAB.grow(2), BRONZE_DARK)
	draw_rect(SLAB, STONE)
	draw_rect(Rect2(SLAB.position, Vector2(SLAB.size.x, 3)), STONE_LIGHT)
	draw_rect(Rect2(SLAB.position.x, SLAB.end.y - 3, SLAB.size.x, 3), STONE_DARK)
	draw_rect(Rect2(SLAB.position.x - 3, SLAB.position.y - 6, SLAB.size.x + 6, 4), BRONZE)
	for x in [SLAB.position.x + 8, SLAB.end.x - 16]:
		draw_rect(Rect2(x, SLAB.end.y, 8, 8), OUTLINE)
		draw_rect(Rect2(x + 1, SLAB.end.y, 6, 7), STONE_DARK)
	if puzzles.is_empty():
		return
	var p := puzzle()
	var filled := p.occupied() if not is_solved else p.target
	var origin := SLAB.get_center() + Vector2(0, 5) - Vector2(p.size) * MINI / 2.0
	for c in p.target:
		var r := Rect2(origin + Vector2(c) * MINI, Vector2(MINI, MINI)).grow(-0.5)
		draw_rect(r, OUTLINE)
		var fill := STONE_DARK.lerp(CYAN.darkened(0.45), 0.35 + 0.15 * sin(_time * 2.0 + c.x + c.y))
		if filled.has(c):
			fill = CYAN.lerp(GOLD, glow)
		draw_rect(r.grow(-1), fill)
	if not is_solved:
		_text_center("%d / %d" % [current + 1, puzzles.size()], Vector2(0, SLAB.position.y + 11), 8, GOLD)


func _text_center(text: String, at: Vector2, size: int, color: Color) -> void:
	var big := size * 2
	var w := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, big).x
	draw_set_transform(at.round(), 0.0, Vector2(0.5, 0.5))
	draw_string_outline(_font, Vector2(-w / 2.0, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, big, 4, OUTLINE)
	draw_string(_font, Vector2(-w / 2.0, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, big, color)
	draw_set_transform(Vector2.ZERO)
