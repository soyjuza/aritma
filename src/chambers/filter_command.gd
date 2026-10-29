## Patrón Command: un paso del programa de la Criba.
class_name FilterCommand
extends RefCounted


func run(_machine: CribaMachine) -> void:
	pass


## Llena la tolva. rows: [[numero, color], ...]
class RoundStart extends FilterCommand:
	var index: int
	var rows: Array

	func _init(p_index: int, p_rows: Array) -> void:
		index = p_index
		rows = p_rows

	func run(machine: CribaMachine) -> void:
		await machine.load_round(index, rows)


## Baja la siguiente esfera.
class Release extends FilterCommand:
	var value: int

	func _init(p_value: int) -> void:
		value = p_value

	func run(machine: CribaMachine) -> void:
		await machine.drop_to_gate()


## La esfera va al cáliz o al crisol.
class Send extends FilterCommand:
	var value: int
	var to_chalice: bool
	var right: bool

	func _init(p_value: int, p_to_chalice: bool, p_right: bool) -> void:
		value = p_value
		to_chalice = p_to_chalice
		right = p_right

	func run(machine: CribaMachine) -> void:
		await machine.send_from_gate(to_chalice, right)


## La consulta trajo otras columnas: la Criba se traba.
class Jam extends FilterCommand:
	func run(machine: CribaMachine) -> void:
		await machine.jam()


class RoundDone extends FilterCommand:
	var index: int

	func _init(p_index: int) -> void:
		index = p_index

	func run(machine: CribaMachine) -> void:
		await machine.round_done(index)
