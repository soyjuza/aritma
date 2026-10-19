## Corre solo las pruebas del lenguaje del Códice, sin abrir el juego:
##   Godot --headless --path . -s res://src/tests/script_lang_runner.gd
extends SceneTree


func _init() -> void:
	var tests := ScriptLangTests.new()
	var failures := tests.run_all(func(ok, label): print(("  ok   " if ok else "  FALLO ") + label))
	print("LENGUAJE ", "OK" if failures == 0 else "FALLO (%d)" % failures)
	quit(0 if failures == 0 else 1)
