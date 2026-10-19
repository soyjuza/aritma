## Un personaje que espera en el mundo (Orun). Se le habla con E; talk_key es la clave de su
## conversación en data/texts.json.
class_name Npc
extends Node2D

@export var talk_key := ""

@onready var talk_area: Interactable = $Charla
