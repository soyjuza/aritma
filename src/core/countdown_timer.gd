## Cuenta regresiva del desafío (15 minutos por defecto).
## Publica eventos en vez de llamar a otros objetos: quien quiera reaccionar al
## fin del tiempo o al aviso del último minuto se suscribe al EventBus.
class_name CountdownTimer
extends RefCounted

var limit: float
var warning_at: float
var remaining: float
var active := false
var _bus: EventBus
var _last_warned_second := -1


func _init(bus: EventBus, limit_sec: float, warning_sec: float) -> void:
	_bus = bus
	limit = limit_sec
	warning_at = warning_sec
	remaining = limit_sec


func reset() -> void:
	remaining = limit
	active = false
	_last_warned_second = -1


func start() -> void:
	active = true


func stop() -> void:
	active = false


func elapsed() -> float:
	return limit - remaining


func is_warning() -> bool:
	return remaining <= warning_at


func tick(delta: float) -> void:
	if not active:
		return
	remaining = max(0.0, remaining - delta)
	var second := int(ceil(remaining))
	if is_warning() and second != _last_warned_second:
		_last_warned_second = second
		_bus.publish(GameEvents.TIME_WARNING, {"seconds": second})
	if remaining <= 0.0:
		active = false
		_bus.publish(GameEvents.TIME_UP)


static func format(seconds: float) -> String:
	var s := int(ceil(seconds))
	return "%d:%02d" % [s / 60, s % 60]
