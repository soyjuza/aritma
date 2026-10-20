## Patrón State: cansado después del pisotón.
class_name BossTiredState
extends BossState


func physics(delta: float) -> String:
	t += delta
	boss.brake(delta)
	return "chase" if t >= boss.tired_time else ""


func animation() -> String:
	return "hit"


func draw() -> void:
	for i in 3:
		var a := t * 5.0 + i * TAU / 3.0
		boss.draw_circle(Vector2(0, -50) + Vector2(cos(a) * 9.0, sin(a) * 3.0), 1.2, Color("ffc857"))
