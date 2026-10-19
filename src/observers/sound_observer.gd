## PATRÓN OBSERVER — Observador concreto: efectos de sonido.
## La tabla evento → sonido viene de config.json. Ninguna regla del juego llama al audio
## directamente; solo publican eventos y este observador decide qué sonido corresponde.
class_name SoundObserver
extends RefCounted

var _audio: AudioService


func _init(bus: EventBus, audio: AudioService, sounds: Dictionary) -> void:
	_audio = audio
	for event in sounds.keys():
		var sound := String(sounds[event])
		bus.subscribe(StringName(event), func(_payload): _audio.play_sfx(sound))
