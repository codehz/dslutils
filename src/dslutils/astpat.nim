import std/[macros, tables, strutils]
import ./identsubs

func equalNode(a, b: NimNode): NimNode =
  nnkInfix.newTree(bindSym "==", a, b)

func `and=`(base: var NimNode, expr: NimNode) =
  if expr == newLit true:
    return
  if base == newLit true:
    base = expr
  else:
    base = nnkInfix.newTree(bindSym "and", base, expr)

func `or=`(base: var NimNode, expr: NimNode) =
  if expr == newLit false:
    return
  if base == newLit false:
    base = expr
  else:
    base = nnkInfix.newTree(bindSym "or", base, expr)

const identlists = {nnkSym, nnkIdent}
const strlits = {nnkStrLit, nnkRStrLit, nnkTripleStrLit}
const intlits = {nnkCharLit..nnkUInt64Lit}
const floatlits = {nnkFloatLit..nnkFloat128Lit}
const simplenode = {nnkSym, nnkIdent, nnkCharLit..nnkNilLit}

func genInSet(node: NimNode, name: static string): NimNode =
  nnkInfix.newTree(
    bindSym "in",
    newDotExpr(node, bindSym "kind"),
    bindSym name
  )

func match(this, expr: NimNode, cache: var Table[string, NimNode]): NimNode =
  result = newLit true
  case expr.kind:
  of nnkAccQuoted:
    if expr.len == 1:
      result = genInSet(this, "simplenode")
      if not expr[0].strVal.startsWith "_":
        cache[expr[0].strVal] = this
    elif expr.len == 2:
      expr[1].expectIdent "*"
      if not expr[0].strVal.startsWith "_":
        cache[expr[0].strVal] = this
    else:
      error("invalid quote: " & repr expr)
  of identlists:
    result = genInSet(this, "identlists")
    result.and = equalNode(newDotExpr(this, bindSym "strVal"), newLit expr.strVal)
  of strlits:
    result = genInSet(this, "strlits")
    result.and = equalNode(newDotExpr(this, bindSym "strVal"), newLit expr.strVal)
  of intlits:
    result = genInSet(this, "intlits")
    result.and = equalNode(newDotExpr(this, bindSym "intVal"), newLit expr.intVal)
  of floatlits:
    result = genInSet(this, "floatlits")
    result.and = equalNode(newDotExpr(this, bindSym "floatVal"), newLit expr.floatVal)
  of nnkCallKinds:
    result = genInSet(this, "nnkCallKinds")
    result.and = equalNode(newDotExpr(this, bindSym "len"), newLit expr.len)
    for idx, item in expr.pairs:
      result.and = match(nnkBracketExpr.newTree(this, newLit idx), item, cache)
  else:
    result = equalNode(newDotExpr(this, bindSym "kind"), newLit expr.kind)
    result.and = equalNode(newDotExpr(this, bindSym "len"), newLit expr.len)
    for idx, item in expr.pairs:
      result.and = match(nnkBracketExpr.newTree(this, newLit idx), item, cache)

func matchExact(this, expr: NimNode, cache: var Table[string, NimNode]): NimNode =
  let nkid = ident("nnk" & expr[0].strVal)
  result = equalNode(newDotExpr(this, bindSym "kind"), nkid)
  var splat = false
  func idx(src: int, xsplat = splat): int =
    if xsplat: expr.len - 1 - src
    else: src
  func getidx(src: int): NimNode =
    result = nnkBracketExpr.newTree(this)
    if splat:
      result.add nnkPrefix.newTree(bindSym "^", newLit src.idx)
    else:
      result.add newLit src.idx
  var after = newLit true
  for i, item in expr[1..^1].pairs():
    case item.kind:
    of nnkIdent:
      result.and = equalNode(newDotExpr(getidx(i), bindSym "kind"), ident("nnk" & item.strVal))
    of nnkCallKinds:
      result.and = matchExact(getidx(i), item, cache)
    of nnkAccQuoted:
      if item.len == 1:
        if not item[0].strVal.startsWith "_":
          cache[item[0].strVal] = getidx(i)
      elif item.len == 2:
        item[1].expectIdent "*"
        assert not splat
        if not item[0].strVal.startsWith "_":
          cache[item[0].strVal] = nnkBracketExpr.newTree(
            this,
            nnkInfix.newTree(
              ident "..^",
              newLit idx(i),
              newLit idx(i, true)
            )
          )
          splat = true
      else:
        error("invalid quote: " & repr item)
    of nnkPar, nnkTupleConstr, nnkStmtList:
      item.expectLen 1
      after.and = match(getidx(i), item[0], cache)
    else:
      error("invalid element")
  if splat:
    result.and = nnkInfix.newTree(bindSym ">=", newDotExpr(this, bindSym "len"), newLit (expr.len - 1))
  else:
    result.and = equalNode(newDotExpr(this, bindSym "len"), newLit (expr.len - 1))
  result.and = after

macro `case`*(stmt: NimNode): untyped =
  result = nnkIfStmt.newTree()
  let expr = stmt[0]
  let branches = stmt[1..^1]
  for branch in branches:
    if branch.len >= 2:
      let body = branch[^1]
      var cache: Table[string, NimNode]
      var generated = newLit false
      for conds in branch[0..^2]:
        if conds.kind in nnkCallKinds:
          generated.or = matchExact(expr, conds, cache)
        else:
          conds.expectLen 1
          generated.or = match(expr, conds[0], cache)
      let gbody = newStmtList()
      for k, v in cache:
        gbody.add newLetStmt(ident k, v)
      for line in body:
        if line.kind in nnkCallKinds and line.len == 2:
          let fn = line[0]
          let fbody = line[1]
          if fn.kind in identlists and fn.strVal == "guard":
            generated.and = identsubs(fbody, cache)
            continue
        gbody.add line
      result.add nnkElifBranch.newTree(generated, gbody)
    else:
      result.add nnkElse.newTree(branch[0])
