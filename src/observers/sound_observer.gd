## Patrón Observer: pone el sonido de cada evento.
class_name SoundObserver
extends RefCounted

var _audio: AudioService


func _init(bus: EventBus, audio: AudioService, sounds: Dictionary) -> void:
	_audio = audio
	for event in sounds.keys():
		var sound := String(sounds[event])
		bus.subscribe(StringName(event), func(_payload): _audio.play_sfx(sound))
