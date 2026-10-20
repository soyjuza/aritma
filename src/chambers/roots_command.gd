## PATRÓN COMMAND — Cada ecuación probada es una orden: se anota al correr el programa (al
## instante) y el Mural (el invocador) la ejecuta después con su animación: se enciende la
## placa, gira el engranaje y aparece la x que despejó el jugador.
class_name RootsCommand
extends RefCounted

var index: int
var verdict: RootsTrial.Verdict
var shown: String        # lo que aparece en la placa de resultado
var steps: int


func _init(p_index: int, p_verdict: RootsTrial.Verdict, p_shown: String, p_steps: int) -> void:
	index = p_index
	verdict = p_verdict
	shown = p_shown
	steps = p_steps


func run(machine: MuralMachine) -> void:
	await machine.test_row(index, verdict, shown, steps)
