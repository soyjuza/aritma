## Registra los controles de config.json en el InputMap.
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


## Nombres de los botones del ratón (texts.json).
static var mouse_names: Dictionary = {}


## Nombres de los botones táctiles (texts.json "touch_names").
static var touch_names: Dictionary = {}
static var touch := false


## Nombre de la primera tecla de una acción.
static func key_name(action: String) -> String:
	if touch and touch_names.has(action):
		return String(touch_names[action])
	if not InputMap.has_action(action):
		return "?"
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			return OS.get_keycode_string(event.keycode)
		if event is InputEventMouseButton:
			var names := {MOUSE_BUTTON_LEFT: "left", MOUSE_BUTTON_RIGHT: "right"}
			return String(mouse_names.get(names.get(event.button_index, "other"), "?"))
	return "?"


## Sin ratón real el clic no golpea ni gira: eso lo hacen los botones.
static func drop_mouse_bindings() -> void:
	for action in InputMap.get_actions():
		for event in InputMap.action_get_events(action):
			if event is InputEventMouseButton:
				InputMap.action_erase_event(action, event)


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
