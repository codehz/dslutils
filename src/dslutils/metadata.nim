import macros

type WithMetadata[T, M: typed] = distinct T

converter `@`*[T, M: typed](source: WithMetadata[T, M]): T = T source

type WithoutMetadata*[T] = concept value
  `@`(value) is T

template metadata(value: untyped) {.pragma.}
template typedmetadata(value: typed) {.pragma.}

template `.`*[T](left: WithoutMetadata[T], field: untyped{nkIdent}): untyped =
  (@left).field

template `~~`*(value: typed, meta: untyped): untyped =
  type host {.metadata: meta.} = object
  WithMetadata[typeof(value), host] value

template `~@`*(value: typed, meta: typed): untyped =
  type host {.typedmetadata: meta.} = object
  WithMetadata[typeof(value), host] value

func `metadata`*(value: NimNode): NimNode =
  value.expectKind nnkSym
  let inst = value.getTypeInst
  inst.expectKind nnkBracketExpr
  assert inst[0] == bindSym "WithMetadata"
  value.getTypeInst[2].getImpl[0][1][0][1]
