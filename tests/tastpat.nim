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
