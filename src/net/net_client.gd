## Conexión WebSocket con el servidor de salas. Game la revisa en cada cuadro (poll).
## Los mensajes son diccionarios JSON con el campo "t" (tipo).
class_name NetClient
extends RefCounted

signal opened
signal closed
signal message(msg: Dictionary)

var _peer: WebSocketPeer
var _last_state := WebSocketPeer.STATE_CLOSED


func open(url: String) -> Error:
	close()
	_peer = WebSocketPeer.new()
	_peer.inbound_buffer_size = 1 << 18
	_last_state = WebSocketPeer.STATE_CONNECTING
	var err := _peer.connect_to_url(url)
	if err != OK:
		_peer = null
		_last_state = WebSocketPeer.STATE_CLOSED
	return err


func close() -> void:
	if _peer:
		_peer.close()
	_peer = null
	_last_state = WebSocketPeer.STATE_CLOSED


func is_open() -> bool:
	return _peer != null and _peer.get_ready_state() == WebSocketPeer.STATE_OPEN


func is_connecting() -> bool:
	return _peer != null and _peer.get_ready_state() == WebSocketPeer.STATE_CONNECTING


func send(msg: Dictionary) -> void:
	if is_open():
		_peer.send_text(JSON.stringify(msg))


func poll() -> void:
	if _peer == null:
		return
	_peer.poll()
	var state := _peer.get_ready_state()
	if state != _last_state and state == WebSocketPeer.STATE_OPEN:
		_last_state = state
		opened.emit()
	# Primero los mensajes: el último puede llegar junto con el cierre
	while _peer and _peer.get_available_packet_count() > 0:
		var parsed = JSON.parse_string(_peer.get_packet().get_string_from_utf8())
		if parsed is Dictionary and parsed.has("t"):
			message.emit(parsed)
	if _peer and state == WebSocketPeer.STATE_CLOSED:
		_peer = null
		_last_state = state
		closed.emit()
