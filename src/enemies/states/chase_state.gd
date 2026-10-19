## PATRÓN STATE — Persigue a Tala en formación. Los de cuerpo a cuerpo van a su lugar
## alrededor de ella (Guardian.formation_target) y, al alcance, preparan el golpe. Los de
## distancia se mantienen lejos: huyen si Tala se acerca, se acercan si está lejos, se mueven
## de lado mientras tanto y preparan un disparo cuando la tienen a tiro. Si Tala cayó vencida,
## se quedan quietos.
class_name ChaseState
extends GuardianState

var _strafe := 1.0
var _strafe_left := 0.0
var _blocked_for := 0.0     # segundos sin línea libre hacia Tala


func enter() -> void:
	super()
	guardian.glow = 0.0
	guardian.eyes.energy = 1.2


func physics(delta: float) -> String:
	var p := guardian.player()
	if p == null or p.dead or p.falling:
		guardian.velocity = guardian.velocity.move_toward(Vector2.ZERO, 400.0 * delta)
		guardian.move_and_slide()
		return ""
	var to := guardian.to_player()
	if to.length() > 0.1:
		guardian.facing = to.normalized()
	if guardian.is_ranged():
		return _keep_distance(to, delta)
	if to.length() <= guardian.reach + 4.0 and guardian.in_formation():
		guardian.velocity = guardian.velocity.move_toward(Vector2.ZERO, 600.0 * delta)
		guardian.move_and_slide()
		return "windup" if guardian.cooldown <= 0.0 else ""
	var target := guardian.formation_target()
	var dir := (target - guardian.global_position)
	var want := (dir.normalized() if dir.length() > 2.0 else Vector2.ZERO) * guardian.speed * guardian.speed_scale + guardian.separation()
	guardian.velocity = guardian.velocity.move_toward(want, 500.0 * delta)
	guardian.move_and_slide()
	return ""


func _keep_distance(to: Vector2, delta: float) -> String:
	_strafe_left -= delta
	var blocked := not guardian.clear_shot()
	_blocked_for = _blocked_for + delta if blocked else 0.0
	var d := to.length()
	var side_dir := to.normalized().orthogonal() * _strafe
	# Da la vuelta si choca de frente con algo hacia el lado al que va; sin línea libre
	# sigue rodeando hacia el mismo lado hasta encontrarla
	var hit := guardian.get_last_slide_collision()
	var wall_ahead := hit != null and hit.get_normal().dot(side_dir) < -0.6
	if wall_ahead or (_strafe_left <= 0.0 and not blocked):
		_strafe = -_strafe
		_strafe_left = randf_range(1.2, 2.4)
	var away := -to.normalized()
	var side := to.normalized().orthogonal() * _strafe
	if _blocked_for > 2.5 and guardian.blink():
		_blocked_for = 0.0
		return ""
	var want := Vector2.ZERO
	if _blocked_for > 0.8:
		# Algo le tapa el tiro (una máquina, una columna): se acerca bordeándolo
		want = (-away * 0.8 + side * 0.6).normalized() * guardian.speed
		# Pegado a un obstáculo: avanza a lo largo de él (no contra él)
		if hit:
			var along := want.slide(hit.get_normal())
			if along.length() > 0.1:
				want = along.normalized() * guardian.speed
	elif d < guardian.keep_distance - 22.0:
		want = (away + side * 0.4).normalized() * guardian.speed * 1.25
	elif d > guardian.keep_distance + 26.0:
		want = (-away + side * 0.3).normalized() * guardian.speed
	else:
		want = side * guardian.speed * (1.0 if blocked else 0.6)
	want = want * guardian.speed_scale + guardian.separation()
	guardian.velocity = guardian.velocity.move_toward(want, 500.0 * delta)
	guardian.move_and_slide()
	if d <= guardian.shot_range and guardian.cooldown <= 0.0 and not blocked:
		return "windup"
	return ""


func animation() -> String:
	return "walk" if guardian.velocity.length() > 4.0 else "idle"


func hittable() -> bool:
	return true
