import std/[tables, macros]

func identsubs*(expr: NimNode, replacements: Table[string, NimNode]): NimNode =
  if expr.kind == nnkIdent:
    copy replacements[expr.strVal]
  elif expr.kind in nnkCallKinds and expr[0].kind in { nnkIdent, nnkSym }:
    expr[1] = identsubs(expr[1], replacements)
    expr
  else:
    expr[0] = identsubs(expr[0], replacements)
    expr

func identsubs*(expr: NimNode, replacements: openArray[(string, NimNode)]): NimNode =
  expr.identsubs(replacements.toTable)
