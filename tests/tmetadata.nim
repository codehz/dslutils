import dslutils/metadata
import std/macros

let value = 5 ~~ { meta: 1 }
let tmp = "abc"
let typedmeta = 6 ~@ { "meta": tmp }

macro dumpMetadata(target: typed) =
  let meta = target.metadata
  for kv in meta:
    echo treerepr kv

dumpMetadata value
dumpMetadata typedmeta

echo value
echo typedmeta