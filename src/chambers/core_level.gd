## Sala 5: el Sendero sobre el abismo. Solo aguantan las losas que cumplen la regla.
class_name CoreLevel
extends ChamberLevel

var _in_hall := false
var _won := false
var _rule: Dictionary = {}          # {"multiple": 3, "text": "múltiplos de 3"}
var _rng := RandomNumberGenerator.new()

@onready var stones: NumberPath = $Sendero


func wire() -> void:
	var seed_value := int(data.get("seed", 0))
	if seed_value != 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()
	var rules: Array = data.get("rules", [{"multiple": 3, "text": "múltiplos de 3"}])
	_rule = rules[_rng.randi_range(0, rules.size() - 1)]
	data = data.duplicate(true)
	data["intro"] = rule_lines("intro")
	var path: Dictionary = data.get("path", {})
	stones.cols = int(path.get("cols", stones.cols))
	stones.rows = int(path.get("rows", stones.rows))
	stones.generate(_rng, int(_rule.get("multiple", 3)), int(path.get("extra_safe", 3)), int(path.get("top", 60)))
	$Zonas/EntradaSala.crossed.connect(_on_hall_entered)


## Textos de la sala con la regla puesta.
func rule_lines(key: String) -> Array:
	return data.get(key, []).map(func(line): return String(line).format({"regla": _rule.get("text", "")}))


func _on_hall_entered() -> void:
	_in_hall = true
	objective_key = "objective_core_path"
	_game.dialog.say(data.get("intro", []))


func hud_line() -> String:
	if not _in_hall or _won:
		return ""
	return _game.data.message("hud_path_rule", {"regla": _rule.get("text", "")})


func _physics_process(_delta: float) -> void:
	var player: PlayerController = _game.player if _game else null
	if player == null or _won or player.falling or player.airborne or player.dead or player.get_parent() != actors:
		return
	if not _game.machine.current is PlayState:
		return
	if not stones.over_void(player.global_position):
		return
	var c := stones.cell_at(player.global_position)
	if c == stones.goal:
		_take_core()
	elif c == Vector2i(-1, -1) or stones.broken.has(c):
		player_fall()
	elif not stones.is_safe(c):
		_wrong_stone(c)


## Losa mala: se rompe y Tala cae.
func _wrong_stone(c: Vector2i) -> void:
	stones.crumble(c)
	_game.bus.publish(GameEvents.STONE_BROKEN)
	await player_fall()
	_game.notify([_game.data.message("path_wrong_stone", {"n": stones.numbers[c], "regla": _rule.get("text", "")})], 5.0)


func player_fall() -> void:
	await _game.player.fall()
	await _on_player_fell()


## Tala toma el núcleo.
func _take_core() -> void:
	_won = true
	stones.core_taken = true
	_game.player.controls_enabled = false
	_game.bus.publish(GameEvents.CORE_TAKEN)
	_game.rig.shake(5.0)
	_game.notify([_game.data.message("core_taken")], 4.0)
	await get_tree().create_timer(2.0).timeout
	solved = true
	alarm.calm()
	if _game.data.chamber_count() > index + 1:
		_game.enter_chamber(index + 1)
	else:
		_game.finish(true)
