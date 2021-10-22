import std/[tables, macros]

func identsubs*(expr: NimNode, replacements: Table[string, NimNode]): NimNode =
  if expr.kind == nnkIdent:
    return copy replacements[expr.strVal]
  elif expr.kind in nnkCallKinds and expr[0].kind in { nnkIdent, nnkSym }:
    result = copy expr
    result[1] = identsubs(expr[1], replacements)
  else:
    result = copy expr
    result[0] = identsubs(expr[0], replacements)

func identsubs*(expr: NimNode, replacements: openArray[(string, NimNode)]): NimNode =
  expr.identsubs(replacements.toTable)
