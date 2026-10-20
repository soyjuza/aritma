## Patrón Strategy: perfil de efectos. create() elige cuál usar.
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
