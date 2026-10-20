## Reglas de vidas y castigos de tiempo (config.json, "combat").
class_name LifeRules
extends RefCounted

const FALL_DELAY := 1.6

var _game: Game


func _init(game: Game) -> void:
	_game = game
	game.bus.subscribe(GameEvents.PLAYER_DIED, func(_p): _on_player_died())


## Resta segundos al reloj (solo dentro del templo).
func penalize(seconds: float) -> void:
	var timer := _game.timer
	if not timer.active or seconds <= 0.0:
		return
	timer.remaining = maxf(0.0, timer.remaining - seconds)
	_game.notices.penalty(seconds)
	_game.bus.publish(GameEvents.TIME_PENALTY, {"seconds": seconds})


func _on_player_died() -> void:
	_game.player.die()
	await _game.get_tree().create_timer(FALL_DELAY, true, false, true).timeout
	if _game.machine.current is EndState:
		return
	var cost := float(_game.combat("death_penalty_sec", 60))
	if _game.timer.remaining <= cost:
		_game.finish(false, "ending_no_lives")
		return
	penalize(cost)
	_game.notify([_game.data.message("player_no_lives", {"s": int(cost)})], 4.0)
	await _game.fade_out()
	_game.health.refill()
	_game.level.restart_after_death()
	_game.fade_in()
