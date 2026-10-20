## Avisos de arriba y el "-7 s". Solo guarda qué mostrar; el HUD lo dibuja.
class_name NoticeBoard
extends RefCounted

const PENALTY_SECONDS := 2.2     # cuánto flota el "−7 s"

var text := ""
var left := 0.0
var good := false
var penalty_text := ""
var penalty_left := 0.0


func notify(lines: Array, seconds := 5.0, is_good := false) -> void:
	text = " ".join(lines)
	left = seconds
	good = is_good


func penalty(seconds: float) -> void:
	penalty_text = "−%d s" % int(seconds)
	penalty_left = PENALTY_SECONDS


func tick(delta: float) -> void:
	left = maxf(0.0, left - delta)
	penalty_left = maxf(0.0, penalty_left - delta)
