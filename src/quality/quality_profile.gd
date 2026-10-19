## PATRÓN STRATEGY (comportamiento) — Perfil de efectos. Cada perfil decide si las luces
## proyectan sombras y cuántas partículas se dibujan; el juego usa el perfil elegido sin
## saber cuál es. create() es una pequeña fábrica que elige la estrategia por índice.
class_name QualityProfile
extends RefCounted

var preset: Dictionary = {}


static func create(index: int, presets: Dictionary) -> QualityProfile:
	var profile: QualityProfile = HighQuality.new() if index >= 1 else LowQuality.new()
	profile.preset = presets.get(profile.id(), {})
	return profile


func id() -> String:
	return ""


func shadows() -> bool:
	return bool(preset.get("shadows", false))


func particle_scale() -> float:
	return float(preset.get("particles", 1.0))
