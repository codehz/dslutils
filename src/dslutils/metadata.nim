import std/macros

type WithMetadata[T, M: typed] {.borrow: `.`.} = distinct T

converter `@`*[T, M: typed](source: WithMetadata[T, M]): T = T source

type WithoutMetadata*[T] = concept value
  T is type
  `@`(value) is T

template metadata(value: untyped) {.pragma.}
template typedmetadata(value: typed) {.pragma.}

template `~~`*(value: typed, meta: untyped): untyped =
  type host {.metadata: meta, used.} = object
  WithMetadata[typeof(value), host] value

template `~@`*(value: typed, meta: typed): untyped =
  type host {.typedmetadata: meta, used.} = object
  WithMetadata[typeof(value), host] value

func `metadata`*(value: NimNode): NimNode =
  value.expectKind nnkSym
  let inst = value.getTypeInst
  inst.expectKind nnkBracketExpr
  assert inst[0] == bindSym "WithMetadata"
  value.getTypeInst[2].getImpl[0][1][0][1]

func withMetadata*(value: NimNode, meta: NimNode): NimNode =
  result = newStmtList()
  let vt = value.getTypeInst()
  let gt = nskType.genSym "host"
  result.add nnkTypeSection.newTree(nnkTypeDef.newTree(
    nnkPragmaExpr.newTree(
      gt,
      nnkPragma.newTree(
        newColonExpr(bindSym "metadata", meta),
        ident "used"
      )
    ),
    newEmptyNode(),
    nnkObjectTy.newTree(newEmptyNode(), newEmptyNode(), newEmptyNode())
  ))
  let genret = nnkBracketExpr.newTree(bindSym "WithMetadata", vt, gt)
  result.add newCall(genret, value)
