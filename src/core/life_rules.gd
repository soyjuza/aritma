## Reglas de vidas (config.json, "combat").
class_name LifeRules
extends RefCounted

const FALL_DELAY := 1.6

var _game: Game


func _init(game: Game) -> void:
	_game = game
	game.bus.subscribe(GameEvents.PLAYER_DIED, func(_p): _on_player_died())


## Una caída cuesta medio corazón.
func fall_damage() -> void:
	_game.health.damage(int(_game.combat("fall_damage_halves", 1)))


## Sin corazones: vuelve a la entrada de la sala con la vida llena.
func _on_player_died() -> void:
	_game.player.die()
	await _game.get_tree().create_timer(FALL_DELAY, true, false, true).timeout
	if _game.machine.current is EndState:
		return
	await _game.fade_out()
	_game.health.refill()
	_game.level.restart_after_death()
	_game.fade_in()
