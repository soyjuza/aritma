## Personaje con el que se habla con E. Con quest_id da una misión (data/quests.json).
class_name Npc
extends Node2D

@export var talk_key := ""
@export var quest_id := ""

## Estado de su misión ("", "active", "done"); lo conecta el nivel.
var quest_state := Callable()

var _time := 0.0
var _font: Font

@onready var talk_area: Interactable = $Charla


func _ready() -> void:
	_font = load(UIKit.PIXEL_FONT)


func _process(delta: float) -> void:
	if quest_id == "":
		return
	_time += delta
	queue_redraw()


## "!" si tiene misión para dar, "?" si está esperando.
func _draw() -> void:
	if quest_id == "" or not quest_state.is_valid() or _font == null:
		return
	var s := String(quest_state.call())
	if s == "done":
		return
	var mark := "!" if s == "" else "?"
	var at := Vector2(-2.5, -19.0 + sin(_time * 3.0) * 1.5)
	draw_string_outline(_font, at, mark, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 4, Color("14181c"))
	draw_string(_font, at, mark, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("ffd27a"))
