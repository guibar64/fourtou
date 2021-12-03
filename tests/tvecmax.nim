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

template testFunc(fn, baseFn, data1, data2) =
  let res = toArray(fn(vecF64(data1),vecF64(data2)))
  echo res
  for i, x in data1:
    check res[i], baseFn(data1[i], data2[i])

var data,data2: array[simdSize div 8, float64]
for i in 0..<data.len: 
  data[i] = NaN
  data2[i] = 1.0

testFunc(simd.max, max, data,data2)
