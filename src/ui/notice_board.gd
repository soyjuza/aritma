## Avisos de arriba. Solo guarda qué mostrar; el HUD lo dibuja.
class_name NoticeBoard
extends RefCounted

var text := ""
var left := 0.0
var good := false
var place := false    # nombre del lugar al llegar (dorado)


func notify(lines: Array, seconds := 5.0, is_good := false, is_place := false) -> void:
	text = " ".join(lines)
	left = seconds
	good = is_good
	place = is_place


func tick(delta: float) -> void:
	left = maxf(0.0, left - delta)
