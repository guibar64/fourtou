
when defined(amd64) and not defined(simdNoSimd):
  when defined(simdSSE41):
    import sse41
    export sse41
  elif defined(simdAVX2):
    import avx2
    export avx2
  elif defined(simdAVX512):
    import avx512
    export avx512
  else:
    import sse2
    export sse2
else:
  const
    simdSize* = 0
  type
    VecF32* = float32
    VecF64* = float64
  template vec*(a: array[1, float32]): VecF32 = a[0]
  template vec*(a: array[1, float64]): VecF64 = a[0]
  template vec*(a: float32): VecF32 = a
  template vec*(a: float64): VecF64 = a
