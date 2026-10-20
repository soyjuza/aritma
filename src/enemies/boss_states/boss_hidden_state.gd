## Patrón State: escondido hasta que Tala toca el núcleo.
class_name BossHiddenState
extends BossState


func enter() -> void:
	super()
	boss.visible = false
	boss.body_shape.set_deferred("disabled", true)
	boss.bar.visible = false


func hittable() -> bool:
	return false
