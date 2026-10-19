## Los corazones de Tala. Se cuentan en mitades (5 corazones = 10 mitades): el golpe de un
## centinela quita media. No sabe nada de dibujos ni de sonidos: publica eventos y el HUD,
## el sonido y el nivel reaccionan (patrón Observer).
class_name PlayerHealth
extends RefCounted

var max_halves := 10
var halves := 10
var _bus: EventBus


func _init(bus: EventBus, hearts := 5) -> void:
	_bus = bus
	max_halves = hearts * 2
	halves = max_halves


func hearts() -> int:
	return max_halves / 2


func is_dead() -> bool:
	return halves <= 0


## Quita "amount" mitades. Devuelve true si con este golpe se acabaron los corazones.
func damage(amount: int) -> bool:
	if is_dead() or amount <= 0:
		return false
	halves = maxi(0, halves - amount)
	_bus.publish(GameEvents.PLAYER_HURT, {"halves": halves, "amount": amount})
	if is_dead():
		_bus.publish(GameEvents.PLAYER_DIED)
		return true
	return false


func heal(amount: int) -> void:
	var before := halves
	halves = mini(max_halves, halves + amount)
	if halves > before:
		_bus.publish(GameEvents.PLAYER_HEALED, {"halves": halves})


func refill() -> void:
	halves = max_halves
