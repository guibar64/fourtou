
when defined(amd64) and not defined(simdNoSSE2):
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
  const simdCFlag* = ""
  const
    simdSize* = 8
  type
    VecF32* = float32
    VecF64* = float64
  template vec*(a: array[1, float32]): VecF32 = a[0]
  template vec*(a: array[1, float64]): VecF64 = a[0]
  template vec*(a: float32): VecF32 = a
  template vec*(a: float64): VecF64 = a

  template storeu*(a: ptr float64, b: VecF64) = a[] = b
  template store*(a: ptr float64, b: VecF64) = a[] = b
  template loadu*(a: ptr float64): VecF64 = a[]
  template load*(a: ptr float64): VecF64 = a[]
  template storeu*(a: ptr float32, b: VecF32) = a[] = b
  template store*(a: ptr float32, b: VecF32) = a[] = b
  template loadu*(a: ptr float32): VecF32 = a[]
  template load*(a: ptr float32): VecF32 = a[]

  template toArray*(a: VecF32): array[1, float32] = [a]
  template toArray*(a: VecF64): array[1, float64] = [a]