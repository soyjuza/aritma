## Fundido a negro entre salas.
class_name ScreenFade
extends RefCounted

const SPEED := 3.0

var amount := 0.0    # 0 se ve todo, 1 negro
var _dir := 0.0
var _tree: SceneTree


func _init(tree: SceneTree) -> void:
	_tree = tree


func fade_in() -> void:
	amount = 1.0
	_dir = -1.0


func fade_out() -> void:
	_dir = 1.0
	while amount < 1.0:
		await _tree.process_frame
	await _tree.process_frame


func tick(delta: float) -> void:
	if _dir != 0.0:
		amount = clampf(amount + _dir * delta * SPEED, 0.0, 1.0)
