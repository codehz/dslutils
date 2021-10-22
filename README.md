# A macro collection for creating DSL in nim

Current modules: astpat, identsubs

## ASTPAT: Do pattern match on nim ast

**WARNING:** require experimental option: caseStmtMacros, you can enable it by pragma `{.experimental: "caseStmtMacros".}`

usage:

```nim
case line:
of (`key` = `value*`):
  # key match only "simple" node like ident, sym, string, int
  # value* match all node
  echo repr key, " = ", repr value
of (a.`key` = func(`value*`)):
  echo "a.", repr key, " = func(", repr value, ")"
```

## IDENTSUBS: Replace left most identifier in expression

usage:

```nim

type MyObj = object
  vint: int
  varr: array[2, int]

proc fun(self: MyObj) = echo repr self

var a = MyObj(vint: 1)
var b = MyObj(vint: 2, varr: [5, 6])

macro withObj(body: untyped{nkStmtList}) =
  result = newStmtList()
  for item in body.items:
    result.add: item.identsubs: {
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
```

result:

```nim
a.vint = 4
a.varr[0] = 1
a.fun()
fun(b)
```