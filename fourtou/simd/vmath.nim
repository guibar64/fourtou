
when defined(amd64) and not defined(simdNoSSE2):
  when defined(simdSSE41):
    import ./vmath_sse2
    export vmath_sse2
  elif defined(simdAVX2):
    import vmath_avx2
    export vmath_avx2
  elif defined(simdAVX512):
    import vmath_avx512
    export vmath_avx512
  else:
    import ./vmath_sse2
    export vmath_sse2
else:
  const
    simdSize* = 1
  type
    VecF32* = float32
    VecF64* = float64
