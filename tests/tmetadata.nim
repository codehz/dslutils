import dslutils/metadata
import std/macros

let value = 5 ~~ { meta: 1 }
let tmp = "abc"
let typedmeta = 6 ~@ { "meta": tmp }
let wrong = "" ~~ 1

macro dumpMetadata(target: typed) =
  echo treerepr target.metadata

template testConcept(value: WithoutMetadata[int]) = discard

dumpMetadata value
dumpMetadata typedmeta

testConcept value
static:
  assert not compiles(testConcept wrong)

echo value
echo typedmeta

macro gen(v: typed): untyped =
  let sym = bindSym "tmp"
  result = withMetadata(v, sym)

let x = gen(5)

dumpMetadata(x)