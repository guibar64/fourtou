import math #except `^`
import complex

#export complex
export math #except `^`

template `^`*[T:SomeFloat](x: T, y: T): auto = pow(x,y)

template `^`*(x: SomeFloat, n: int{lit}): auto =
  when n == 1:
    x
  elif n==2:
    x*x
  else:
    pow(x,type(x)(n))

    
template `^`*(x: SomeFloat, n: int): auto =
  if n == 1:
    x
  elif n==2:
    x*x
  else:
    pow(x,type(x)(n))

#template ``*(n,p: int): auto = n^p


proc plgndr[T: SomeFloat, I: SomeInteger](L,m: I,x: T): T {.noSideEffect.} =
  ## Computes the associated renormalized Legendre polynomial Pm
  ## l (*x*). Here *m* and *L* are integers satisfying
  ## 0 ≤ m ≤ L, while x lies in the range −1 ≤ x ≤ 1.
  var pmm=1.0 #Compute Pmm
  if m > 0:
    let somx2=sqrt((1.0-x)*(1.0+x))
    var fact=1.0
    for ll in 1..m:
      pmm *= -fact*somx2
      fact += 2.0
  
  if L == m:
    result=pmm
  else:
    var pmmp1=x*T(2*m+1)*pmm #Compute Pmm+1.
    if L == m+1:
      result=pmmp1
    else: #Compute Pml , l > m+ 1.
      var pll: T
      for ll in m+2..L:
        pll=(x*T(2*ll-1)*pmmp1-T(ll+m-1)*pmm)/T(ll-m)
        pmm=pmmp1
        pmmp1=pll
      result=pll


proc SpherHarmAmp*[T: SomeFloat, I: SomeInteger](L,m: I, costheta: T): T {.noSideEffect.}=
  ## Spherical harmonic amplitude of order *l* and *m*. 
  ## *costheta* is the cosine of the azimutal angle
  let mm=abs(m)
  var fact=1
  for i in countdown(L+mm,L-mm+1):
     fact=fact*i
  result=sqrt(T(2*L+1)/(4*fact.T*Pi))*plgndr(L,mm,costheta)
      
proc SpherHarm*[T: SomeFloat, I: SomeInteger](L,m: I, cosTheta,phi: T): Complex[T] {.noSideEffect, inline.} =
  ## Spherical harmonic of order *l* and *m*. *unx,uny,unz*
  ## *costheta* is the cosine of the azimutal angle
  ## and *phi* the other angle
  #let phi=arctan2(uny,unx)
  let res_norm = SpherHarmAmp(L,m, cosTheta)
  result.re = res_norm*cos(m.T*phi)
  result.im = res_norm*sin(m.T*phi)

when not defined(JS):
  # Additional (C99) functions. 

  # double functions
 

  proc ldexp*(a2: float64; a3: cint): float64 {.importc: "ldexp", header: "<math.h>".}

  proc c_modf(a2: float64; a3: ptr float64): float64 {.importc: "modf", header: "<math.h>".}

  proc modf*(x:float64): tuple[frac:float64,integ:float64] {.inline.} =
    var n:float64
    result.frac=c_modf(x, addr n)
    result.integ = n

  proc acosh*(a2: float64): float64 {.importc: "acosh", header: "<math.h>".}
  proc asinh*(a2: float64): float64 {.importc: "asinh", header: "<math.h>".}
  proc atanh*(a2: float64): float64 {.importc: "atanh", header: "<math.h>".}

  proc exp2*(a2: float64): float64 {.importc: "exp2", header: "<math.h>".}
  proc expm1*(a2: float64): float64 {.importc: "expm1", header: "<math.h>".}
  proc fma*(a2: float64; a3: float64; a4: float64): float64 {.importc: "fma",
                                                            header: "<math.h>".}

  proc hypot*(a2: float64; a3: float64): float64 {.importc: "hypot",
                                                 header: "<math.h>".}
  proc ilogb*(a2: float64): cint {.importc: "ilogb", header: "<math.h>".}
  #proc isinf*(a2: float64): cint
  #proc isnan*(a2: float64): cint
  proc lgamma*(a2: float64): float64 {.importc: "lgamma", header: "<math.h>".}
  proc llrint*(a2: float64): clonglong {.importc: "llrint", header: "<math.h>".}
  proc llround*(a2: float64): clonglong {.importc: "llround", header: "<math.h>".}
  proc log1p*(a2: float64): float64 {.importc: "log1p", header: "<math.h>".}
 
  proc logb*(a2: float64): float64 {.importc: "logb", header: "<math.h>".}
  proc lrint*(a2: float64): clong {.importc: "lrint", header: "<math.h>".}
  proc lround*(a2: float64): clong {.importc: "lround", header: "<math.h>".}
 # proc nan*(a2: cstring): float64 {.importc: "nan", header: "<math.h>".}
  proc nextafter*(a2: float64; a3: float64): float64 {.importc: "nextafter",
                                                     header: "<math.h>".}
  proc remainder*(a2: float64; a3: float64): float64 {.importc: "remainder",
                                                     header: "<math.h>".}
  proc remquo*(a2: float64; a3: float64; a4: ptr cint): float64 {.importc: "remquo",
                                                                header: "<math.h>".}
  proc rint*(a2: float64): float64 {.importc: "rint", header: "<math.h>".}

  proc j0*(a2: float64): float64 {.importc: "j0", header: "<math.h>".}
  proc j1*(a2: float64): float64 {.importc: "j1", header: "<math.h>".}
  proc jn*(a2: cint; a3: float64): float64 {.importc: "jn", header: "<math.h>".}
  proc y0*(a2: float64): float64 {.importc: "y0", header: "<math.h>".}
  proc y1*(a2: float64): float64 {.importc: "y1", header: "<math.h>".}
  proc yn*(a2: cint; a3: float64): float64 {.importc: "yn", header: "<math.h>".}

  proc gamma*(a2: float64): float64 {.importc: "gamma", header: "<math.h>".}

  proc scalb*(a2: float64; a3: float64): float64 {.importc: "scalb",
                                                 header: "<math.h>".}

  proc copysign*(a2: float64; a3: float64): float64 {.importc: "copysign",
                                                    header: "<math.h>".}
#   proc fdim*(a2: float64; a3: float64): float64 {.importc: "fdim", header: "<math.h>".}
#   proc fmax*(a2: float64; a3: float64): float64 {.importc: "fmax", header: "<math.h>".}
#   proc fmin*(a2: float64; a3: float64): float64 {.importc: "fmin", header: "<math.h>".}
  proc nearbyint*(a2: float64): float64 {.importc: "nearbyint", header: "<math.h>".}
  proc round*(a2: float64): float64 {.importc: "round", header: "<math.h>".}
  proc scalbln*(a2: float64; a3: clong): float64 {.importc: "scalbln",
                                                 header: "<math.h>".}
  proc scalbn*(a2: float64; a3: cint): float64 {.importc: "scalbn", header: "<math.h>".}


  proc drem*(a2: float64; a3: float64): float64 {.importc: "drem", header: "<math.h>".}
  proc finite*(a2: float64): cint {.importc: "finite", header: "<math.h>".}


  proc significand*(a2: float64): float64 {.importc: "significand",
                                          header: "<math.h>".}

 #  float versions of ANSI/POSIX functions

  proc exp2*(a2: float32): float32 {.importc: "exp2f", header: "<math.h>".}
  proc expm1*(a2: float32): float32 {.importc: "expm1f", header: "<math.h>".}

  
  proc ilogb*(a2: float32): cint {.importc: "ilogbf", header: "<math.h>".}
  proc ldexp*(a2: float32; a3: cint): float32 {.importc: "ldexpf", header: "<math.h>".}
  proc log1p*(a2: float32): float32 {.importc: "log1pf", header: "<math.h>".}

  proc c_modf(a2: float32; a3: ptr float32): float32 {.importc: "modff",
                                                   header: "<math.h>".}
  proc modf*(x:float32): tuple[frac:float32,integ:float64] =
    var n:float32
    result.frac=c_modf(x, addr n)
    result.integ = n

  proc hypot*(a2: float32; a3: float32): float32 {.importc: "hypotf", header: "<math.h>".}

  proc acosh*(a2: float32): float32 {.importc: "acoshf", header: "<math.h>".}
  proc asinh*(a2: float32): float32 {.importc: "asinhf", header: "<math.h>".}
  proc atanh*(a2: float32): float32 {.importc: "atanhf", header: "<math.h>".}
  proc cbrt*(a2: float32): float32 {.importc: "cbrtf", header: "<math.h>".}
  proc logb*(a2: float32): float32 {.importc: "logbf", header: "<math.h>".}
  proc copysign*(a2: float32; a3: float32): float32 {.importc: "copysignf",
                                                      header: "<math.h>".}
  proc llrint*(a2: float32): clonglong {.importc: "llrintf", header: "<math.h>".}
  proc llround*(a2: float32): clonglong {.importc: "llroundf", header: "<math.h>".}
  proc lrint*(a2: float32): clong {.importc: "lrintf", header: "<math.h>".}
  proc lround*(a2: float32): clong {.importc: "lroundf", header: "<math.h>".}
  proc nan*(a2: cstring): float32 {.importc: "nanf", header: "<math.h>".}
  proc nearbyint*(a2: float32): float32 {.importc: "nearbyintf", header: "<math.h>".}
  proc nextafter*(a2: float32; a3: float32): float32 {.importc: "nextafterf",
                                                       header: "<math.h>".}
  proc remainder*(a2: float32; a3: float32): float32 {.importc: "remainderf",
                                                       header: "<math.h>".}
  proc remquo*(a2: float32; a3: float32; a4: ptr cint): float32 {.importc: "remquof",
                                                                  header: "<math.h>".}
  proc rint*(a2: float32): float32 {.importc: "rintf", header: "<math.h>".}
  proc scalbln*(a2: float32; a3: clong): float32 {.importc: "scalblnf",
                                                   header: "<math.h>".}
  proc scalbn*(a2: float32; a3: cint): float32 {.importc: "scalbnf", header: "<math.h>".}
 
  proc fdim*(a2: float32; a3: float32): float32 {.importc: "fdimf", header: "<math.h>".}
  proc fma*(a2: float32; a3: float32; a4: float32): float32 {.importc: "fmaf",
                                                              header: "<math.h>".}
  proc fmax*(a2: float32; a3: float32): float32 {.importc: "fmaxf", header: "<math.h>".}
  proc fmin*(a2: float32; a3: float32): float32 {.importc: "fminf", header: "<math.h>".}
  ## 
  ##  float versions of BSD math library entry points
  ## 

  proc drem*(a2: float32; a3: float32): float32 {.importc: "dremf", header: "<math.h>".}
  proc finite*(a2: float32): cint {.importc: "finitef", header: "<math.h>".}

  proc j0*(a2: float32): float32 {.importc: "j0f", header: "<math.h>".}
  proc j1*(a2: float32): float32 {.importc: "j1f", header: "<math.h>".}
  proc jn*(a2: cint; a3: float32): float32 {.importc: "jnf", header: "<math.h>".}
  proc scalb*(a2: float32; a3: float32): float32 {.importc: "scalbf", header: "<math.h>".}
  proc y0*(a2: float32): float32 {.importc: "y0f", header: "<math.h>".}
  proc y1*(a2: float32): float32 {.importc: "y1f", header: "<math.h>".}
  proc yn*(a2: cint; a3: float32): float32 {.importc: "ynf", header: "<math.h>".}


  proc significand*(a2: float32): float32 {.importc: "significandf",
                                          header: "<math.h>".}



# tent float128
#   type cldouble {.importc: "long double".} = object
#   when sizeof(cldouble) == 16:
#     type Float128* = cldouble

