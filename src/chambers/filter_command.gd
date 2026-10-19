## PATRÓN COMMAND — Cada paso del programa de la Criba es un objeto: se anota mientras el
## programa corre (al instante) y después la máquina 3D (el invocador, CribaMachine) los
## ejecuta uno por uno con su animación. Así se ve, esfera por esfera, lo que ordenó el código.
class_name FilterCommand
extends RefCounted


## Ejecuta la orden sobre la máquina (espera a que termine su animación).
func run(_machine: CribaMachine) -> void:
	pass


## La tolva se llena con las esferas de una ronda.
class RoundStart extends FilterCommand:
	var index: int
	var values: Array

	func _init(p_index: int, p_values: Array) -> void:
		index = p_index
		values = p_values

	func run(machine: CribaMachine) -> void:
		await machine.load_round(index, values)


## La siguiente esfera baja por el tubo hasta la compuerta.
class Release extends FilterCommand:
	var value: int

	func _init(p_value: int) -> void:
		value = p_value

	func run(machine: CribaMachine) -> void:
		await machine.drop_to_gate()


## La compuerta se inclina y la esfera rueda al cáliz o al crisol.
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


## El programa terminó con esferas sin clasificar: la máquina se traba.
class Jam extends FilterCommand:
	func run(machine: CribaMachine) -> void:
		await machine.jam()


## Ronda superada.
class RoundDone extends FilterCommand:
	var index: int

	func _init(p_index: int) -> void:
		index = p_index

	func run(machine: CribaMachine) -> void:
		await machine.round_done(index)
