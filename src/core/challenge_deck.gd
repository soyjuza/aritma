## Elige al azar la variante de cada sala ("variants" en chambers.json).
## Con la misma semilla salen los mismos ejercicios: así el espectador ve la sala del otro.
class_name ChallengeDeck
extends RefCounted


## Índice de sala -> datos de la sala con su variante puesta.
## fixed: siempre la primera variante (pruebas automáticas).
static func roll(chambers: Array, seed_value: int, fixed := false) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var out := {}
	for i in chambers.size():
		out[i] = resolve(chambers[i], rng, fixed)
	return out


static func resolve(base: Dictionary, rng: RandomNumberGenerator, fixed := false) -> Dictionary:
	var out := base.duplicate(true)
	var variants: Array = out.get("variants", [])
	out.erase("variants")
	# La semilla de la sala sale de la partida (pruebas: al azar, como antes)
	var room_seed := rng.randi_range(1, 2147483646)
	if not fixed and int(out.get("seed", 0)) == 0:
		out["seed"] = room_seed
	if variants.is_empty():
		return out
	var pick: Dictionary = variants[0 if fixed else rng.randi_range(0, variants.size() - 1)]
	var params := {}
	var choices: Dictionary = pick.get("params", {})
	for key in choices:
		var options: Array = choices[key]
		params[key] = options[0 if fixed else rng.randi_range(0, options.size() - 1)]
	for key in pick:
		if key != "params":
			out[key] = fill(pick[key], params)
	out["params"] = params
	return out


## Pone los {marcadores} en textos, listas y diccionarios.
static func fill(value, params: Dictionary):
	if value is String:
		return value.format(params)
	if value is Array:
		return value.map(func(v): return fill(v, params))
	if value is Dictionary:
		var out := {}
		for key in value:
			out[key] = fill(value[key], params)
		return out
	return value
