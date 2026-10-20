## Patrón State: pisotón. Salta y cae donde estaba Tala.
class_name BossSlamState
extends BossState

const FOLLOW_UP := 2.5
const FOLLOW_DOWN := 6.0

var target := Vector2.ZERO


func enter() -> void:
	super()
	var p := boss.player()
	target = p.global_position if p else boss.global_position
	if boss.arena.has_area():
		target = target.clamp(boss.arena.position, boss.arena.end)
	boss.publish(GameEvents.GUARDIAN_CHARGING)


func physics(delta: float) -> String:
	t += delta
	if t < boss.slam_rise:
		boss.lift = boss.slam_height * sin(t / boss.slam_rise * PI * 0.5)
		boss.global_position = boss.global_position.lerp(target, delta * FOLLOW_UP)
		return ""
	if t < boss.slam_land:
		boss.lift = boss.slam_height * (1.0 - (t - boss.slam_rise) / (boss.slam_land - boss.slam_rise))
		boss.global_position = boss.global_position.lerp(target, delta * FOLLOW_DOWN)
		return ""
	boss.lift = 0.0
	boss.wave_ring = 0.0
	boss.publish(GameEvents.BOSS_SLAM)
	var p := boss.player()
	if p and not p.airborne and p.global_position.distance_to(boss.global_position) <= boss.slam_radius:
		p.hurt(boss.slam_damage, boss.global_position)
	return "tired"


## Círculo rojo donde va a caer.
func draw() -> void:
	var at := target - boss.global_position
	var k := clampf(t / boss.slam_land, 0.0, 1.0)
	boss.draw_circle(at, boss.slam_radius, Color(ZeroBoss.RED, 0.10 + 0.15 * k))
	boss.draw_arc(at, boss.slam_radius, 0, TAU, 40, Color(ZeroBoss.RED, 0.9), 1.0)
	boss.draw_arc(at, boss.slam_radius * k, 0, TAU, 40, Color(ZeroBoss.RED, 0.6), 1.0)
