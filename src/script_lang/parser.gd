## Parser: convierte las fichas en el árbol de nodos (Interpreter).
class_name Parser
extends RefCounted

const AUGMENTED := {"+=": "+", "-=": "-", "*=": "*", "/=": "/", "//=": "//", "%=": "%", "**=": "**"}
const COMPARE_OPS := ["==", "!=", "<", "<=", ">", ">="]

var error := ""
var error_line := 0

var _tokens: Array
var _pos := 0


## Devuelve el bloque raíz o null si hay error.
func parse(tokens: Array) -> ScriptNode:
	_tokens = tokens
	_pos = 0
	var block := ScriptNodes.Block.new()
	while not _at("EOF") and error == "":
		if _accept_kind("NEWLINE"):
			continue
		var statement := _statement()
		if statement:
			block.statements.append(statement)
	return null if error != "" else block


# ------------------------------------------------------------------ instrucciones

func _statement() -> ScriptNode:
	var t: Lexer.Token = _peek()
	if t.kind == "INDENT":
		_fail(ScriptMessages.text("sangria_inesperada_esta_linea_no"), t.line)
		return null
	if t.kind == "KEYWORD":
		match t.value:
			"if":
				return _if()
			"while":
				_advance()
				var condition := _expression()
				var body := _block_after_colon("while")
				return ScriptNodes.While.new(condition, body, t.line) if body else null
			"for":
				return _for()
			"def":
				return _def()
			"return":
				_advance()
				var value: ScriptNode = null if _at("NEWLINE") else _expression()
				_end_line()
				return ScriptNodes.Return.new(value, t.line)
			"break", "continue", "pass":
				_advance()
				_end_line()
				return ScriptNodes.Flow.new(t.value, t.line)
			"elif", "else":
				_fail(ScriptMessages.text("sin_if_antes") % t.value, t.line)
				return null
	return _simple_statement()


func _simple_statement() -> ScriptNode:
	var line: int = _peek().line
	var expr := _expression()
	if error != "":
		return null
	var t: Lexer.Token = _peek()
	if t.is_op("=") or (t.kind == "OP" and AUGMENTED.has(t.value)):
		if not (expr is ScriptNodes.Name or expr is ScriptNodes.Index or expr is ScriptNodes.Attribute):
			_fail(ScriptMessages.text("izquierda_debe_ir_nombre_variable") % t.value, t.line)
			return null
		_advance()
		var value := _expression()
		_end_line()
		return ScriptNodes.Assign.new(expr, value, "" if t.value == "=" else AUGMENTED[t.value], line)
	_end_line()
	return ScriptNodes.ExprStatement.new(expr, line)


func _if() -> ScriptNode:
	var node := ScriptNodes.If.new()
	node.line = _advance().line
	node.conditions.append(_expression())
	var first := _block_after_colon("if")
	if not first:
		return null
	node.blocks.append(first)
	while _peek().is_keyword("elif"):
		_advance()
		node.conditions.append(_expression())
		var block := _block_after_colon("elif")
		if not block:
			return null
		node.blocks.append(block)
	if _peek().is_keyword("else"):
		_advance()
		node.otherwise = _block_after_colon("else")
	return node


func _for() -> ScriptNode:
	var line: int = _advance().line
	var name_token: Lexer.Token = _peek()
	if name_token.kind != "NAME":
		_fail(ScriptMessages.text("despues_for_va_nombre_variable"), line)
		return null
	_advance()
	if not _peek().is_keyword("in"):
		_fail(ScriptMessages.text("falta_in_for_in_range") % name_token.value, line)
		return null
	_advance()
	var iterable := _expression()
	var body := _block_after_colon("for")
	return ScriptNodes.For.new(name_token.value, iterable, body, line) if body else null


func _def() -> ScriptNode:
	var line: int = _advance().line
	var name_token: Lexer.Token = _peek()
	if name_token.kind != "NAME":
		_fail(ScriptMessages.text("despues_def_va_nombre_funcion"), line)
		return null
	_advance()
	if not _accept_op("("):
		_fail(ScriptMessages.text("faltan_los_parentesis_def_n") % name_token.value, line)
		return null
	var params: Array = []
	while not _peek().is_op(")"):
		var p: Lexer.Token = _advance()
		if p.kind != "NAME":
			_fail(ScriptMessages.text("los_parametros_deben_ser_nombres"), line)
			return null
		params.append(p.value)
		if not _accept_op(","):
			break
	if not _accept_op(")"):
		_fail(ScriptMessages.text("falta_cerrar_parentesis_def"), line)
		return null
	var body := _block_after_colon("def")
	return ScriptNodes.FunctionDef.new(name_token.value, params, body, line) if body else null


func _block_after_colon(what: String) -> ScriptNodes.Block:
	var t: Lexer.Token = _peek()
	if not _accept_op(":"):
		_fail(ScriptMessages.text("falta_final_linea") % what, t.line)
		return null
	if not _accept_kind("NEWLINE") or not _accept_kind("INDENT"):
		_fail(ScriptMessages.text("las_instrucciones_van_las_lineas") % what, t.line)
		return null
	var block := ScriptNodes.Block.new()
	block.line = t.line
	while not _at("DEDENT") and not _at("EOF") and error == "":
		if _accept_kind("NEWLINE"):
			continue
		var statement := _statement()
		if statement:
			block.statements.append(statement)
	_accept_kind("DEDENT")
	return block if error == "" else null


func _end_line() -> void:
	if error != "":
		return
	if not (_accept_kind("NEWLINE") or _at("EOF") or _at("DEDENT")):
		var t: Lexer.Token = _peek()
		_fail(ScriptMessages.text("no_esperaba_aqui") % str(t.value), t.line)


# ------------------------------------------------------------------ expresiones

func _expression() -> ScriptNode:
	return _or()


func _or() -> ScriptNode:
	var left := _and()
	while _peek().is_keyword("or"):
		var line: int = _advance().line
		left = ScriptNodes.BoolOp.new("or", left, _and(), line)
	return left


func _and() -> ScriptNode:
	var left := _not()
	while _peek().is_keyword("and"):
		var line: int = _advance().line
		left = ScriptNodes.BoolOp.new("and", left, _not(), line)
	return left


func _not() -> ScriptNode:
	if _peek().is_keyword("not"):
		var line: int = _advance().line
		return ScriptNodes.Unary.new("not", _not(), line)
	return _comparison()


func _comparison() -> ScriptNode:
	var first := _bit_or()
	var ops: Array = []
	var operands: Array = [first]
	while true:
		var t: Lexer.Token = _peek()
		if t.kind == "OP" and t.value in COMPARE_OPS:
			_advance()
			ops.append(t.value)
		elif t.is_keyword("in"):
			_advance()
			ops.append("in")
		elif t.is_keyword("not") and _peek(1).is_keyword("in"):
			_advance()
			_advance()
			ops.append("not in")
		else:
			break
		operands.append(_bit_or())
	return first if ops.is_empty() else ScriptNodes.Compare.new(ops, operands, first.line if first else 0)


func _bit_or() -> ScriptNode:
	return _binary_level(["|"], _bit_xor)


func _bit_xor() -> ScriptNode:
	return _binary_level(["^"], _bit_and)


func _bit_and() -> ScriptNode:
	return _binary_level(["&"], _shift)


func _shift() -> ScriptNode:
	return _binary_level(["<<", ">>"], _arith)


func _arith() -> ScriptNode:
	return _binary_level(["+", "-"], _term)


func _term() -> ScriptNode:
	return _binary_level(["*", "/", "//", "%"], _unary)


func _binary_level(ops: Array, next: Callable) -> ScriptNode:
	var left: ScriptNode = next.call()
	while _peek().kind == "OP" and _peek().value in ops:
		var t: Lexer.Token = _advance()
		left = ScriptNodes.Binary.new(t.value, left, next.call(), t.line)
	return left


func _unary() -> ScriptNode:
	var t: Lexer.Token = _peek()
	if t.kind == "OP" and t.value in ["-", "+", "~"]:
		_advance()
		return ScriptNodes.Unary.new(t.value, _unary(), t.line)
	return _power()


func _power() -> ScriptNode:
	var base := _postfix()
	if _peek().is_op("**"):
		var t: Lexer.Token = _advance()
		return ScriptNodes.Binary.new("**", base, _unary(), t.line)
	return base


func _postfix() -> ScriptNode:
	var node := _atom()
	while error == "":
		var t: Lexer.Token = _peek()
		if t.is_op("("):
			_advance()
			var args: Array = []
			while not _peek().is_op(")") and error == "":
				args.append(_expression())
				if not _accept_op(","):
					break
			if not _accept_op(")"):
				_fail(ScriptMessages.text("falta_cerrar_parentesis_llamada"), t.line)
				return null
			node = ScriptNodes.Call.new(node, args, t.line)
		elif t.is_op("."):
			_advance()
			var name_token: Lexer.Token = _advance()
			if name_token.kind != "NAME":
				_fail(ScriptMessages.text("despues_punto_va_nombre_puerta"), t.line)
				return null
			node = ScriptNodes.Attribute.new(node, name_token.value, t.line)
		elif t.is_op("["):
			_advance()
			var index := _expression()
			if not _accept_op("]"):
				_fail(ScriptMessages.text("falta_cerrar_corchete"), t.line)
				return null
			node = ScriptNodes.Index.new(node, index, t.line)
		else:
			break
	return node


func _atom() -> ScriptNode:
	var t: Lexer.Token = _advance()
	match t.kind:
		"NUMBER", "STRING":
			return ScriptNodes.Literal.new(t.value, t.line)
		"NAME":
			return ScriptNodes.Name.new(t.value, t.line)
		"KEYWORD":
			match t.value:
				"True":
					return ScriptNodes.Literal.new(true, t.line)
				"False":
					return ScriptNodes.Literal.new(false, t.line)
				"None":
					return ScriptNodes.Literal.new(null, t.line)
		"OP":
			if t.value == "(":
				var inner := _expression()
				if not _accept_op(")"):
					_fail(ScriptMessages.text("falta_cerrar_parentesis"), t.line)
				return inner
			if t.value == "[":
				var items: Array = []
				while not _peek().is_op("]") and error == "":
					items.append(_expression())
					if not _accept_op(","):
						break
				if not _accept_op("]"):
					_fail(ScriptMessages.text("falta_cerrar_lista"), t.line)
				return ScriptNodes.ListLiteral.new(items, t.line)
	if t.kind == "NEWLINE" or t.kind == "EOF":
		_fail(ScriptMessages.text("linea_esta_incompleta"), t.line)
	else:
		_fail(ScriptMessages.text("no_esperaba_aqui") % str(t.value), t.line)
	return ScriptNodes.Literal.new(null, t.line)


# ------------------------------------------------------------------ fichas

func _peek(offset := 0) -> Lexer.Token:
	return _tokens[mini(_pos + offset, _tokens.size() - 1)]


func _advance() -> Lexer.Token:
	var t: Lexer.Token = _peek()
	_pos = mini(_pos + 1, _tokens.size() - 1)
	return t


func _at(kind: String) -> bool:
	return _peek().kind == kind


func _accept_kind(kind: String) -> bool:
	if _at(kind):
		_advance()
		return true
	return false


func _accept_op(op: String) -> bool:
	if _peek().is_op(op):
		_advance()
		return true
	return false


func _fail(message: String, line: int) -> void:
	if error == "":
		error = message
		error_line = line
