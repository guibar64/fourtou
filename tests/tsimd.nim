import miscutils/simd/avx


{.localPassc:"-mavx".}

proc main() =
  block:
    let v1 = m256([1.0f32,2,3,4,5,6,7,8])
    let v2 = m256([-1f32,-2, -6, -8, 1,1,1,1])
    let v3 = v1 + v2
    echo toArray(v3)
    # why echo sqrt(v1) crash ?
    echo sqrt(v1)
    echo v2.toArray[0]
  block:
    let v1 = m256d([1.0f64,2,3,4])
    let v2 = m256d([-1f64,-4, -6, 1])
    let v3 = v1 + v2
    echo toArray(v3)
    let v4 = sqrt(v1)
    echo v4
    echo m256d(1.0f64).toArray[3]
main()