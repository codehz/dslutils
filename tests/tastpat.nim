{.experimental: "caseStmtMacros".}

import std/macros
import dslutils/astpat

macro mydsl(body: untyped{nkStmtList}) =
  for line in body:
    case line:
    of (`key` = `value*`):
      echo repr key, " = ", repr value
    of (a.b = `value*`):
      echo "a.b = ", repr value
    of (a.b.c[`d`] = `value*`):
      echo "a.b.c[", repr d , "] = ", repr value
    of (var `id*` = `value*`):
      guard: id.kind == nnkPragmaExpr
      for pragma in id[1]:
        case pragma:
        of (attrs: `attrs`):
          echo "attrs: ", repr attrs
        of (boom: `boom`):
          echo "boom: ", repr boom
      echo "value: ", repr value
    of (var `id` = `value*`):
      echo "var ", repr id, " = ", repr value
    else:
      echo "unknown: ", repr line

mydsl:
  a = 1
  a.b = 2
  a.b.c[3] = 4
  var boom {.attrs: 1, boom: 2.} = 5
  var plain = 6

macro testobj(test: untyped) =
  for item in test[2][2]:
    case item:
    of IdentDefs(`a`, (float32), `_`):
      echo "mixed: ", repr a
    of IdentDefs(`a*`, `b`, `c`):
      echo "names: ", repr a
      echo "types: ", repr b
      echo "defaults: ", repr c
  test

type X {.testobj, used.} = object
  mixed: float32
  a, b: int
