import std/[tables, macros]

func replaceAll*(expr: NimNode, replacements: Table[string, NimNode]): NimNode =
  if expr.kind == nnkIdent:
    copy replacements[expr.strVal]
  elif expr.kind in nnkCallKinds and expr[0].kind in { nnkIdent, nnkSym }:
    expr[1] = replaceAll(expr[1], replacements)
    expr
  else:
    expr[0] = replaceAll(expr[0], replacements)
    expr

func replaceAll*(expr: NimNode, replacements: openArray[(string, NimNode)]): NimNode =
  expr.replaceAll(replacements.toTable)
