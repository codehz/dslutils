import dslutils/identsubs
import std/macros

type MyObj = object
  vint: int
  varr: array[2, int]

proc fun(self: MyObj) = echo repr self

var a = MyObj(vint: 1)
var b = MyObj(vint: 2, varr: [5, 6])

macro withObj(body: untyped{nkStmtList}) =
  result = newStmtList()
  for item in body.items:
    result.add: item.replaceAll: {
      "vint": newDotExpr(bindSym "a", ident "vint"),
      "varr": newDotExpr(bindSym "a", ident "varr"),
      "primary": bindSym "a",
      "secondary": bindSym "b",
    }

withObj:
  vint = 4
  varr[0] = 1
  primary.fun()
  fun(secondary)