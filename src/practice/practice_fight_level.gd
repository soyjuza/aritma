## Práctica: golpear con el garrote y vencer a un caballero y a un hechicero.
class_name PracticeFightLevel
extends PracticeLevel

const SENTINEL := preload("res://scenes/enemigos/centinela.tscn")
const SORCERER := preload("res://scenes/enemigos/hechicero.tscn")

@onready var dummy: TrainingDummy = $Actores/Muneco


func wire() -> void:
	dummy.hit.connect(_on_dummy_hit)


func on_step(id: String) -> void:
	match id:
		"caballero":
			_drop(SENTINEL)
		"hechicero":
			_drop(SORCERER)


func _on_dummy_hit() -> void:
	if step_id() == "muneco" and dummy.hits >= int(data.get("dummy_hits", 3)):
		complete("muneco")


## Un guardián cae del techo cerca de la marca.
func _drop(scene: PackedScene) -> void:
	var guardian: Guardian = scene.instantiate()
	actors.add_child(guardian)
	guardian.setup(_game.bus, kit, _game.data.setting("combat", {}))
	var id := step_id()
	guardian.defeated.connect(func(_g): complete(id))
	guardian.drop(($Marcas/Caida as Marker2D).global_position)


func guide_point(id: String) -> Vector2:
	if id == "muneco":
		return dummy.global_position + Vector2(0, -10)
	return Vector2.INF


## Si Tala cae sin corazones, el guardián se va y el paso empieza otra vez.
func restart_after_death() -> void:
	for g in nodes_of(Guardian):
		g.queue_free()
	super()
	on_step(step_id())
