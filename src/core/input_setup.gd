## Registra las acciones del juego en el InputMap de Godot a partir de config.json
## ("move_forward": ["key:W", "key:Up"], "scan": ["mouse:1"]...). Así los controles se
## cambian sin tocar el código, y el resto del juego usa Input.is_action_pressed().
class_name InputSetup
extends RefCounted


static func register(controls: Dictionary) -> void:
	for action in controls.keys():
		if InputMap.has_action(action):
			InputMap.erase_action(action)
		InputMap.add_action(action, 0.2)
		for binding in controls[action]:
			var event := _event_for(String(binding))
			if event:
				InputMap.action_add_event(action, event)


## Nombre visible de la primera tecla de una acción ("E", "Shift", "Clic izq.").
static func key_name(action: String) -> String:
	if not InputMap.has_action(action):
		return "?"
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			return OS.get_keycode_string(event.keycode)
		if event is InputEventMouseButton:
			return {MOUSE_BUTTON_LEFT: "Clic izq.", MOUSE_BUTTON_RIGHT: "Clic der."}.get(event.button_index, "Clic")
	return "?"


static func _event_for(binding: String) -> InputEvent:
	var parts := binding.split(":", true, 1)
	if parts.size() != 2:
		return null
	match parts[0]:
		"key":
			var code := OS.find_keycode_from_string(parts[1])
			if code == KEY_NONE:
				push_warning("Tecla desconocida en config.json: " + parts[1])
				return null
			var key := InputEventKey.new()
			key.physical_keycode = code
			key.keycode = code
			return key
		"mouse":
			var button := InputEventMouseButton.new()
			button.button_index = int(parts[1]) as MouseButton
			return button
	return null
