## Patrón Command: una ecuación probada en el Mural.
class_name RootsCommand
extends RefCounted

var index: int
var verdict: RootsTrial.Verdict
var shown: String
var steps: int


func _init(p_index: int, p_verdict: RootsTrial.Verdict, p_shown: String, p_steps: int) -> void:
	index = p_index
	verdict = p_verdict
	shown = p_shown
	steps = p_steps


func run(machine: MuralMachine) -> void:
	await machine.test_row(index, verdict, shown, steps)
