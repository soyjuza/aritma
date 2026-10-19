## PATRÓN INTERPRETER + COMPOSITE — Nodos concretos del lenguaje del Códice.
## Expresiones (Literal, Name, Binary, Call...) e instrucciones (If, While, For, Def...).
## Block es el compuesto: contiene instrucciones y las ejecuta en orden.
class_name ScriptNodes
extends RefCounted


# ================================================================== expresiones

class Literal:
	extends ScriptNode
	var value

	func _init(p_value, p_line: int) -> void:
		value = p_value
		line = p_line

	func evaluate(_ctx: ScriptContext):
		return value


class ListLiteral:
	extends ScriptNode
	var items: Array

	func _init(p_items: Array, p_line: int) -> void:
		items = p_items
		line = p_line

	func evaluate(ctx: ScriptContext):
		var out: Array = []
		for item in items:
			out.append(item.evaluate(ctx))
			if ctx.failed():
				return null
		return out


class Name:
	extends ScriptNode
	var name: String

	func _init(p_name: String, p_line: int) -> void:
		name = p_name
		line = p_line

	func evaluate(ctx: ScriptContext):
		return ctx.lookup(name, line)


class Unary:
	extends ScriptNode
	var op: String
	var operand: ScriptNode

	func _init(p_op: String, p_operand: ScriptNode, p_line: int) -> void:
		op = p_op
		operand = p_operand
		line = p_line

	func evaluate(ctx: ScriptContext):
		var v = operand.evaluate(ctx)
		if ctx.failed():
			return null
		match op:
			"not":
				return not ScriptContext.truthy(v)
			"-", "+":
				if not ScriptContext.is_number(v):
					ctx.fail("No se puede usar «%s» con %s." % [op, ScriptContext.type_name(v)], line)
					return null
				return -v if op == "-" else v
			"~":
				if typeof(v) != TYPE_INT:
					ctx.fail("«~» solo funciona con números enteros.", line)
					return null
				return ~v
		return null


class BoolOp:
	extends ScriptNode
	var op: String
	var left: ScriptNode
	var right: ScriptNode

	func _init(p_op: String, l: ScriptNode, r: ScriptNode, p_line: int) -> void:
		op = p_op
		left = l
		right = r
		line = p_line

	func evaluate(ctx: ScriptContext):
		var a = left.evaluate(ctx)
		if ctx.failed():
			return null
		if op == "and" and not ScriptContext.truthy(a):
			return a
		if op == "or" and ScriptContext.truthy(a):
			return a
		return right.evaluate(ctx)


class Binary:
	extends ScriptNode
	var op: String
	var left: ScriptNode
	var right: ScriptNode

	func _init(p_op: String, l: ScriptNode, r: ScriptNode, p_line: int) -> void:
		op = p_op
		left = l
		right = r
		line = p_line

	func evaluate(ctx: ScriptContext):
		var a = left.evaluate(ctx)
		if ctx.failed():
			return null
		var b = right.evaluate(ctx)
		if ctx.failed():
			return null
		return ScriptNodes.apply_binary(op, a, b, ctx, line)


class Compare:
	extends ScriptNode
	var ops: Array        # ["<", "<="]
	var operands: Array   # [a, b, c]  -> a < b <= c

	func _init(p_ops: Array, p_operands: Array, p_line: int) -> void:
		ops = p_ops
		operands = p_operands
		line = p_line

	func evaluate(ctx: ScriptContext):
		var a = operands[0].evaluate(ctx)
		for i in ops.size():
			var b = operands[i + 1].evaluate(ctx)
			if ctx.failed():
				return null
			if not ScriptNodes.compare(ops[i], a, b, ctx, line):
				return false
			a = b
		return true


class Call:
	extends ScriptNode
	var callee: ScriptNode
	var args: Array

	func _init(p_callee: ScriptNode, p_args: Array, p_line: int) -> void:
		callee = p_callee
		args = p_args
		line = p_line

	func evaluate(ctx: ScriptContext):
		var target = callee.evaluate(ctx)
		if ctx.failed():
			return null
		var values: Array = []
		for arg in args:
			values.append(arg.evaluate(ctx))
			if ctx.failed():
				return null
		if not (target is ScriptCallable):
			ctx.fail("«%s» no es una función: no se puede llamar con ( )." % ScriptContext.to_text(target), line)
			return null
		if not ctx.tick(line):
			return null
		return target.invoke(ctx, values, line)


class Attribute:
	extends ScriptNode
	var target: ScriptNode
	var attr: String

	func _init(p_target: ScriptNode, p_attr: String, p_line: int) -> void:
		target = p_target
		attr = p_attr
		line = p_line

	func evaluate(ctx: ScriptContext):
		var obj = target.evaluate(ctx)
		if ctx.failed():
			return null
		if typeof(obj) == TYPE_ARRAY:
			var method := ScriptNodes.ListMethod.create(obj, attr)
			if method:
				return method
			ctx.fail("Las listas no tienen «%s». Prueba append, pop o len(lista)." % attr, line)
			return null
		if obj is ScriptObject:
			var method: ScriptCallable = obj.get_method(attr)
			if method:
				return method
			return obj.get_attribute(ctx, attr, line)
		ctx.fail("%s no tiene «%s»." % [ScriptContext.type_name(obj), attr], line)
		return null

	func store(ctx: ScriptContext, value) -> void:
		var obj = target.evaluate(ctx)
		if ctx.failed():
			return
		if obj is ScriptObject:
			obj.set_attribute(ctx, attr, value, line)
			return
		ctx.fail("No se puede cambiar «%s» de %s." % [attr, ScriptContext.type_name(obj)], line)


class Index:
	extends ScriptNode
	var target: ScriptNode
	var index: ScriptNode

	func _init(p_target: ScriptNode, p_index: ScriptNode, p_line: int) -> void:
		target = p_target
		index = p_index
		line = p_line

	func evaluate(ctx: ScriptContext):
		var obj = target.evaluate(ctx)
		var i = index.evaluate(ctx)
		if ctx.failed():
			return null
		if obj is ScriptObject:
			return obj.get_index(ctx, i, line)
		if typeof(obj) in [TYPE_ARRAY, TYPE_STRING]:
			if typeof(i) != TYPE_INT:
				ctx.fail("El índice debe ser un número entero.", line)
				return null
			var n: int = obj.length() if typeof(obj) == TYPE_STRING else obj.size()
			var k: int = i + n if i < 0 else i
			if k < 0 or k >= n:
				ctx.fail("Índice %d fuera de rango (hay %d elementos)." % [i, n], line)
				return null
			return obj[k]
		ctx.fail("%s no se puede usar con [ ]." % ScriptContext.type_name(obj), line)
		return null

	func store(ctx: ScriptContext, value) -> void:
		var obj = target.evaluate(ctx)
		var i = index.evaluate(ctx)
		if ctx.failed():
			return
		if typeof(obj) != TYPE_ARRAY or typeof(i) != TYPE_INT:
			ctx.fail("Solo se puede asignar a una posición de una lista.", line)
			return
		var k: int = i + obj.size() if i < 0 else i
		if k < 0 or k >= obj.size():
			ctx.fail("Índice %d fuera de rango (hay %d elementos)." % [i, obj.size()], line)
			return
		obj[k] = value


# ================================================================== instrucciones

class Block:
	extends ScriptNode
	var statements: Array = []

	func execute(ctx: ScriptContext) -> void:
		for statement in statements:
			if not ctx.tick(statement.line):
				return
			statement.execute(ctx)
			if ctx.failed() or ctx.flow != "":
				return


class ExprStatement:
	extends ScriptNode
	var expr: ScriptNode

	func _init(p_expr: ScriptNode, p_line: int) -> void:
		expr = p_expr
		line = p_line

	func execute(ctx: ScriptContext) -> void:
		expr.evaluate(ctx)


class Assign:
	extends ScriptNode
	var target: ScriptNode
	var value: ScriptNode
	var op: String   # "" para =, o "+", "-", "*"... para +=, -=, *=...

	func _init(p_target: ScriptNode, p_value: ScriptNode, p_op: String, p_line: int) -> void:
		target = p_target
		value = p_value
		op = p_op
		line = p_line

	func execute(ctx: ScriptContext) -> void:
		var v = value.evaluate(ctx)
		if ctx.failed():
			return
		if op != "":
			var current = target.evaluate(ctx)
			if ctx.failed():
				return
			v = ScriptNodes.apply_binary(op, current, v, ctx, line)
			if ctx.failed():
				return
		if target is ScriptNodes.Name:
			ctx.assign(target.name, v)
		elif target is ScriptNodes.Index:
			target.store(ctx, v)
		elif target is ScriptNodes.Attribute:
			target.store(ctx, v)
		else:
			ctx.fail("No se puede asignar a eso.", line)


class If:
	extends ScriptNode
	var conditions: Array = []   # [ScriptNode]
	var blocks: Array = []       # [Block]
	var otherwise: Block

	func execute(ctx: ScriptContext) -> void:
		for i in conditions.size():
			var c = conditions[i].evaluate(ctx)
			if ctx.failed():
				return
			if ScriptContext.truthy(c):
				blocks[i].execute(ctx)
				return
		if otherwise:
			otherwise.execute(ctx)


class While:
	extends ScriptNode
	var condition: ScriptNode
	var body: Block

	func _init(p_condition: ScriptNode, p_body: Block, p_line: int) -> void:
		condition = p_condition
		body = p_body
		line = p_line

	func execute(ctx: ScriptContext) -> void:
		while true:
			if not ctx.tick(line):
				return
			var c = condition.evaluate(ctx)
			if ctx.failed() or not ScriptContext.truthy(c):
				return
			body.execute(ctx)
			if ctx.failed():
				return
			if ctx.flow == "break":
				ctx.flow = ""
				return
			if ctx.flow == "continue":
				ctx.flow = ""
			elif ctx.flow == "return":
				return


class For:
	extends ScriptNode
	var variable: String
	var iterable: ScriptNode
	var body: Block

	func _init(p_variable: String, p_iterable: ScriptNode, p_body: Block, p_line: int) -> void:
		variable = p_variable
		iterable = p_iterable
		body = p_body
		line = p_line

	func execute(ctx: ScriptContext) -> void:
		var items = iterable.evaluate(ctx)
		if ctx.failed():
			return
		if typeof(items) == TYPE_STRING:
			items = Array(items.split(""))
		if typeof(items) != TYPE_ARRAY:
			ctx.fail("for necesita una lista o range(...), no %s." % ScriptContext.type_name(items), line)
			return
		for item in items:
			if not ctx.tick(line):
				return
			ctx.assign(variable, item)
			body.execute(ctx)
			if ctx.failed():
				return
			if ctx.flow == "break":
				ctx.flow = ""
				return
			if ctx.flow == "continue":
				ctx.flow = ""
			elif ctx.flow == "return":
				return


class FunctionDef:
	extends ScriptNode
	var name: String
	var params: Array
	var body: Block

	func _init(p_name: String, p_params: Array, p_body: Block, p_line: int) -> void:
		name = p_name
		params = p_params
		body = p_body
		line = p_line

	func execute(ctx: ScriptContext) -> void:
		ctx.assign(name, ScriptNodes.UserFunction.new(self))


class Return:
	extends ScriptNode
	var value: ScriptNode

	func _init(p_value: ScriptNode, p_line: int) -> void:
		value = p_value
		line = p_line

	func execute(ctx: ScriptContext) -> void:
		ctx.return_value = value.evaluate(ctx) if value else null
		ctx.flow = "return"


class Flow:
	extends ScriptNode
	var kind: String   # "break", "continue" o "pass"

	func _init(p_kind: String, p_line: int) -> void:
		kind = p_kind
		line = p_line

	func execute(ctx: ScriptContext) -> void:
		if kind != "pass":
			ctx.flow = kind


# ================================================================== funciones

## Función escrita por el jugador con def.
class UserFunction:
	extends ScriptCallable
	var definition: FunctionDef

	func _init(p_definition: FunctionDef) -> void:
		definition = p_definition
		name = p_definition.name

	func invoke(ctx: ScriptContext, args: Array, line: int):
		if args.size() != definition.params.size():
			ctx.fail("%s() recibe %d argumento(s) y le diste %d." % [name, definition.params.size(), args.size()], line)
			return null
		var locals := {}
		for i in args.size():
			locals[definition.params[i]] = args[i]
		if not ctx.push_frame(locals):
			ctx.fail("Demasiadas llamadas anidadas. ¿%s() se llama a sí misma sin parar?" % name, line)
			return null
		definition.body.execute(ctx)
		ctx.pop_frame()
		var result = ctx.return_value if ctx.flow == "return" else null
		ctx.flow = ""
		ctx.return_value = null
		return result


## Métodos de las listas: append, pop, insert, index, count.
class ListMethod:
	extends ScriptCallable
	var list: Array

	static func create(p_list: Array, method: String) -> ScriptNodes.ListMethod:
		if not method in ["append", "pop", "insert", "index", "count"]:
			return null
		var m := ScriptNodes.ListMethod.new()
		m.list = p_list
		m.name = method
		return m

	func invoke(ctx: ScriptContext, args: Array, line: int):
		match name:
			"append":
				if args.size() != 1:
					ctx.fail("append() recibe 1 argumento.", line)
					return null
				list.append(args[0])
			"pop":
				if list.is_empty():
					ctx.fail("pop() en una lista vacía.", line)
					return null
				return list.pop_back() if args.is_empty() else list.pop_at(int(args[0]))
			"insert":
				list.insert(int(args[0]), args[1])
			"index":
				var k := list.find(args[0])
				if k < 0:
					ctx.fail("%s no está en la lista." % ScriptContext.repr(args[0]), line)
					return null
				return k
			"count":
				return list.count(args[0])
		return null


# ================================================================== operaciones

static func apply_binary(op: String, a, b, ctx: ScriptContext, line: int):
	if op == "+" and typeof(a) == TYPE_STRING and typeof(b) == TYPE_STRING:
		return a + b
	if op == "+" and typeof(a) == TYPE_ARRAY and typeof(b) == TYPE_ARRAY:
		return a + b
	if op == "*" and typeof(a) == TYPE_STRING and typeof(b) == TYPE_INT:
		return a.repeat(maxi(0, b))
	if op in ["^", "&", "|", "<<", ">>"]:
		if typeof(a) != TYPE_INT or typeof(b) != TYPE_INT:
			ctx.fail("«%s» solo funciona con números enteros." % op, line)
			return null
		match op:
			"^":
				return a ^ b
			"&":
				return a & b
			"|":
				return a | b
			"<<":
				return a << b
			">>":
				return a >> b
	if not ScriptContext.is_number(a) or not ScriptContext.is_number(b):
		var tb := ScriptContext.type_name(b)
		ctx.fail("No se puede usar «%s» entre %s %s %s." % [op, ScriptContext.type_name(a), "e" if tb.begins_with("i") else "y", tb], line)
		return null
	if op in ["/", "//", "%"] and b == 0:
		ctx.fail("División entre cero.", line)
		return null
	match op:
		"+":
			return a + b
		"-":
			return a - b
		"*":
			return a * b
		"/":
			return float(a) / float(b)
		"//":
			return ScriptContext.py_floordiv(a, b)
		"%":
			return ScriptContext.py_mod(a, b)
		"**":
			if typeof(a) == TYPE_INT and typeof(b) == TYPE_INT and b >= 0:
				var result := 1
				for i in b:
					result *= a
				return result
			return pow(float(a), float(b))
	ctx.fail("Operador desconocido «%s»." % op, line)
	return null


static func compare(op: String, a, b, ctx: ScriptContext, line: int) -> bool:
	match op:
		"==":
			return _equal(a, b)
		"!=":
			return not _equal(a, b)
		"in", "not in":
			var found := false
			if typeof(b) == TYPE_ARRAY:
				for item in b:
					if _equal(item, a):
						found = true
						break
			elif typeof(b) == TYPE_STRING and typeof(a) == TYPE_STRING:
				found = a in b
			else:
				ctx.fail("«in» necesita una lista o un texto.", line)
				return false
			return found if op == "in" else not found
	var both_numbers := ScriptContext.is_number(a) and ScriptContext.is_number(b)
	var both_text := typeof(a) == TYPE_STRING and typeof(b) == TYPE_STRING
	if not (both_numbers or both_text):
		ctx.fail("No se puede comparar %s con %s." % [ScriptContext.type_name(a), ScriptContext.type_name(b)], line)
		return false
	match op:
		"<":
			return a < b
		"<=":
			return a <= b
		">":
			return a > b
		">=":
			return a >= b
	return false


static func _equal(a, b) -> bool:
	if ScriptContext.is_number(a) and ScriptContext.is_number(b):
		return is_equal_approx(float(a), float(b)) if (typeof(a) == TYPE_FLOAT or typeof(b) == TYPE_FLOAT) else a == b
	if typeof(a) != typeof(b):
		return false
	return a == b
