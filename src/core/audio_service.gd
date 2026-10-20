## Patrón Facade: música y sonidos con funciones simples.
class_name AudioService
extends RefCounted

const BUS_MUSIC := "Music"
const BUS_SFX := "SFX"
const AUDIO_DIR := "res://assets/pack/sounds/%s.wav"
const SFX_VOICES := 4

var _host: Node
var _voices: Array[AudioStreamPlayer] = []
var _next_voice := 0
var _music: AudioStreamPlayer
var _music_name := ""
var _cache: Dictionary = {}


func _init(host: Node) -> void:
	_host = host
	for bus in [BUS_MUSIC, BUS_SFX]:
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
	for i in SFX_VOICES:
		var voice := AudioStreamPlayer.new()
		voice.bus = BUS_SFX
		host.add_child(voice)
		_voices.append(voice)
	_music = AudioStreamPlayer.new()
	_music.bus = BUS_MUSIC
	host.add_child(_music)
	_music.finished.connect(_music.play)


func play_sfx(sound: String) -> void:
	if sound == "":
		return
	var voice := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % _voices.size()
	voice.stream = _load(sound)
	voice.play()


func play_music(track: String) -> void:
	if track == _music_name:
		return
	_music_name = track
	if track == "":
		_music.stop()
		return
	_music.stream = _load(track)
	_music.play()


## level: de 0 a 10
func set_volume(bus_name: String, level: int) -> void:
	var bus := AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_mute(bus, level <= 0)
	AudioServer.set_bus_volume_db(bus, linear_to_db(max(level, 1) / 10.0))


func _load(sound: String) -> AudioStream:
	if not _cache.has(sound):
		_cache[sound] = load(sound if sound.begins_with("res://") else AUDIO_DIR % sound)
	return _cache[sound]
