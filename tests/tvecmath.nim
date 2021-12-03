import std/[strutils]
import math, macros
import fourtou/simd/[simd, vmath]

{.localPassc: simdCFlag.}

proc `~=`(a,b: float): bool = abs(a-b) <= abs(a)*1.0e-12

macro toRepr(n: untyped): untyped =
  result = newLit repr(n)

template check(a,b: float) =
  if not (a ~= b):
    writeStackTrace()
    quit "$1(=$2) !~= $3(=$4)"  % [toRepr(a), $a, toRepr(b), $b]

template testFunc(fn, baseFn, data) =
  let res = toArray(fn(vec(data)))
  for i, x in data:
    check res[i], baseFn(data[i])

var data: array[simdSize div 8, float64]
for i in 0..<data.len: data[i] = (i+1).float

testFunc(exp, exp, data)
testFunc(log, ln, data)
testFunc(sin, sin, data)
testFunc(cos, cos, data)
