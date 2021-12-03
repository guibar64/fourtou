

type InterpKind* = enum
  ikLinear, ikCubic

type InterpObj* = object
  size: int
  kind: InterpKind
  h,hi,h2sur6: float
  x,y,y2: seq[float]

proc len*(itp: InterpObj):int = itp.size
proc bin*(itp: InterpObj):auto = itp.h

proc newInterpObj2points(x,y: openArray[float]): InterpObj =
  result.y = @y[0..1]
  result.x = @x[0..1]
  result.size = 2
  result.h = x[1] - x[0]
  result.h2sur6 = (result.h*result.h)/6.0
  result.hi = 1.0/result.h
  result.y2 = @[0.0, 0.0]


proc sortXY(x,y: openArray[float], n: int): tuple[x,y: seq[float]] =
  result.x = newSeq[float](n)
  result.y = newSeq[float](n)
  
  #TODO Real sort
  for i,xx in x:
    result.x[i] = xx
  for i,yy in y:
    result.y[i] = yy

proc newInterpObj*(x,y: openArray[float], kind=ikCubic): InterpObj =
 # var
    #i: int
    #k: int
  var
    p: float
    qn: float
    sig: float
    un: float
    u: seq[float]
    #y2: seq[float]
  let n = min(x.len, y.len)
  
  let (xx, yy) = sortXY(x,  y, n)
  
  result.kind = kind
  if n==2:
    return newInterpObj2points(xx,yy)
  elif n == 1:
    return InterpObj(size: 2, x: @[xx[0], xx[0]+1], y: @[yy[0], yy[0]], y2: @[0.0, 0.0])
  elif n == 0:
    return InterpObj(size: 2, x: @[0.0, 1], y: @[1.0, 1], y2: @[0.0, 0.0])
  #result = malloc(sizeof((interpcub)))
  result.size = n
  result.h = xx[1] - xx[0]
  result.h2sur6 = (result.h*result.h)/6.0
  result.hi = 1.0/result.h
  
  result.y2 = newSeq[float](n)
  
  if kind == ikCubic:
    u = newSeq[float](n)
    result.y2[0] = 0.0
    u[0] = 0.0
    for i in 1..n-2:
      sig = (xx[i] - xx[i - 1]) / (xx[i + 1] - xx[i - 1])
      p = sig * result.y2[i - 1] + 2.0
      result.y2[i] = (sig - 1.0) / p
      ## u[i] = (6.*((y[i+1]-y[i])/(x[i+1]-x[i])-x[i]-(y[i]-y[i-1])
      ## 		/(x[i]-x[i-1]))/(x[i+1]-x[i-1])-sig*u[i-1])/p;
      u[i] = (6.0 *
          ((yy[i + 1] - yy[i]) / (xx[i + 1] - xx[i]) - (yy[i] - yy[i - 1]) / (xx[i] - xx[i - 1])) /
          (xx[i + 1] - xx[i - 1]) - sig * u[i - 1]) / p

    qn = 0.0
    un = 0.0
    result.y2[n - 1] = (un - qn * u[n - 2]) / (qn * result.y2[n - 2] + 1.0)

    for k in countdown(n-2,0):
      result.y2[k] = result.y2[k] * result.y2[k + 1] + u[k]
  
  #free(u)
  result.y.shallowCopy yy
  result.x.shallowCopy xx


proc findIdx(itp: InterpObj; x: float): int {.inline.} =
  # TODO: stor klo, khi for sequential calls
  var
    klo = 0
    khi = itp.size-1
  while khi-klo>1:
    let k=(khi+klo) div 2
    if itp.x[k] > x:
      khi = k
    else:
      klo=k
  result = klo

proc evalUnsafe*(itp: InterpObj; x: float): float {.inline.} =
  let nr2 = findIdx(itp,x)
#   a -= float(nr2)
  let
    dx = itp.x[nr2+1] - itp.x[nr2]
    a = (x - itp.x[nr2])/dx
    b = 1.0 - a
    c = a*(a*a-1.0)
    d = b*(b*b - 1.0)
    h2sur6 = dx*dx*(1.0/6.0)
  result = itp.y[nr2 + 1] * a + itp.y[nr2] * b +
      (itp.y2[nr2 + 1] * c + itp.y2[nr2] * d )* h2sur6


proc fastEval*( itp: InterpObj; x: float): float {.inline.} = 
  var
    #i: int
    nr2: int
  var
    a: float
    b: float
    h2sur6: float

  h2sur6 = itp.h2sur6 #(itp.h * itp.h) / 6.0
  a = (x - itp.x[0]) * itp.hi
  nr2 = int(a)
  a -= float(nr2)
  b = 1.0 - a
  result = itp.y[nr2 + 1] * a + itp.y[nr2] * b +
      (itp.y2[nr2 + 1] * a * (a * a - 1.0) + itp.y2[nr2] * b * (b * b - 1.0)) * h2sur6

proc evalUnsafe*(itp: InterpObj, x:openArray[float]): seq[float] =
  result = newSeq[float](x.len)
  for i,xx in x:
    result[i] = itp.evalUnsafe(xx)

proc evalAbove*(itp: InterpObj; x: float): float {.inline.} =
  itp.y[^1]

proc evalBelow*(itp: InterpObj; x: float): float {.inline.} =
  itp.y[0]


proc evalSorted*(itp: InterpObj, x:openArray[float]): seq[float] =
  result = newSeq[float](x.len)
  var imin:int = 0
  while x[imin]<itp.x[0]:
    result[imin] = itp.evalBelow(x[imin])
    inc(imin)

  var imax:int = x.high
  while x[imax]>itp.x[^1]:
    result[imax] = itp.evalAbove(x[imax])
    dec(imax)

  for i in imin..imax:
    result[i] = itp.evalUnsafe(x[i])

proc fastEval*(itp: InterpObj, x:openArray[float]): seq[float] =
  result = newSeq[float](x.len)
  var imin:int = 0
  while x[imin]<itp.x[0]:
    result[imin] = itp.evalBelow(x[imin])
  inc(imin)

  var imax:int = x.high
  while x[imax]>itp.x[^1]:
    result[imax] = itp.evalAbove(x[imax])
    dec(imax)


  for i in imin..imax:
    result[i] = itp.fastEval(x[i])


proc `[]`*(itp: InterpObj, x:float): float {.inline.} =
  if unlikely(x >= itp.x[itp.x.high]):
    result = itp.evalAbove(x)
  elif unlikely(x < itp.x[itp.x.low]):
    result = itp.evalBelow(x)
  else:
    result = itp.evalUnsafe(x) # TODO: some proper extrapol ?

proc `[]`*(itp: InterpObj, x:openArray[float]): seq[float] =  
  result = newSeq[float](x.len)
  for i,xx in x:
    result[i] = itp[xx]

