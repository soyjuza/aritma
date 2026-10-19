## Placa de piedra con una inscripción: se lee con E. lines_key es la clave del texto en los
## datos de la sala (data/chambers.json); el nivel lo muestra al usarla.
class_name SignPost
extends Node2D

@export var lines_key := "intro"

@onready var reading: Interactable = $Lectura
