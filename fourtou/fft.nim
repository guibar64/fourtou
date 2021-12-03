import std/complex

# interface to fftw3

{.pragma: fftLib, importc, dynlib("libfftw3.so").}

const
  FFTW_RODFT10 = 9.cint
  FFTW_ESTIMATE = 64.cint
  FFT_FORWARD = cint(-1)
  FFT_BACKWARD = 1.cint
  FFTW_MEASURE = 0.cint

type
  FFTWPlan = distinct pointer

func fftw_malloc(n: int): pointer {.fftLib.}

func fftw_free(p: pointer) {.fftLib.}


proc fftw_plan_r2r_1d(n: cint, i, o: ptr UncheckedArray[cdouble], kind, flags: cint): FFTWPlan {.fftLib.}

proc fftw_plan_dft_r2c_1d(n: cint, i: ptr UncheckedArray[cdouble], o: ptr UncheckedArray[Complex[cdouble]], flags: cint): FFTWPlan {.fftLib.}

proc fftw_plan_dft_c2r_1d(n: cint, i: ptr UncheckedArray[Complex[cdouble]], o: ptr UncheckedArray[cdouble], flags: cint): FFTWPlan {.fftLib.}



proc fftw_execute(p: FFTWPlan) {.fftLib.}

proc fftw_destroy_plan(p: FFTWPlan) {.fftLib.}

template arrayToUnArray(x): untyped = cast[ptr UncheckedArray[typeof(x[0])]](addr x[0])

template unsafeArrayToUnArray(x): untyped = cast[ptr UncheckedArray[typeof(x[0])]](unsafeAddr x[0])


proc rfft*(i: openArray[float], o: var openArray[Complex[float]]) =
  assert(i.len == o.len)
  # let iptr = unsafeArrayToUnArray(i)
  # let optr = arrayToUnArray(o)
  assert(sizeof(float)==sizeof(cdouble))
  let
    iptr = cast[ptr UncheckedArray[float]](fftw_malloc(sizeof(float)*i.len))
    optr = cast[ptr UncheckedArray[Complex[float]]](fftw_malloc(2*sizeof(float)*o.len))
  
  for j in 0..<i.len:
    iptr[j] = i[j]

  var flags = FFTW_ESTIMATE

  let plan = fftw_plan_dft_r2c_1d(cint i.len, iptr, optr,flags)
  assert(plan.pointer != nil)
  fftw_execute(plan)
  fftw_destroy_plan(plan)

  
  for j in 0..<i.len:
    o[j] = optr[j]

  fftw_free(iptr)
  fftw_free(optr)

proc rfft*(i: openArray[float]): seq[Complex[float]] =
  result = newSeq[Complex[float]](i.len)
  rfft(i, result)

proc c2rfft*(i: openArray[Complex[float]], o: var openArray[float]) =
  assert(i.len == o.len)
  # let iptr = unsafeArrayToUnArray(i)
  # let optr = arrayToUnArray(o)
  assert(sizeof(float)==sizeof(cdouble))
  let
    optr = cast[ptr UncheckedArray[float]](fftw_malloc(sizeof(float)*i.len))
    iptr = cast[ptr UncheckedArray[Complex[float]]](fftw_malloc(2*sizeof(float)*o.len))
  
  for j in 0..<i.len:
    iptr[j] = i[j]

  var flags = FFTW_ESTIMATE

  let plan = fftw_plan_dft_c2r_1d(cint i.len, iptr, optr,flags)
  assert(plan.pointer != nil)
  fftw_execute(plan)
  fftw_destroy_plan(plan)

  
  for j in 0..<i.len:
    o[j] = optr[j]

  fftw_free(iptr)
  fftw_free(optr)

proc c2rfft*(i: openArray[Complex[float]]): seq[float] =
  result = newSeq[float](i.len)
  c2rfft(i, result)
