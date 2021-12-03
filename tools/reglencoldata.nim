import std/[strformat, math]
import fourtou/[txtcoldata]

proc reglen(x,y,sigma: openArray[float]): tuple[a ,b , sigmaa, sigmab: float] =
  var mx, my, mx2, myx, ms2, ms2x, ms2x2 = 0.0
  for i in 0..<x.len:
    mx += x[i]
    my += y[i]
    mx2 += x[i]*x[i]
    myx += y[i]*x[i]
    ms2 += sigma[i]*sigma[i]
    ms2x += sigma[i]*sigma[i]*x[i]
    ms2x2 += sigma[i]*sigma[i]*x[i]*x[i]
  let Nf = x.len.float
  mx /= Nf
  my /= Nf
  mx2 /= Nf
  myx /= Nf
  ms2 /= Nf
  ms2x2 /= Nf
  ms2x /= Nf
  #TODO: a et sb
  ((myx-mx*my)/(mx2-mx*mx) , 0.0, sqrt((ms2x2+ms2*mx2-2*ms2x*mx)/Nf)/(mx2-mx*mx), 0.0 )

proc reglencoldata(uncer = true, files: seq[string]) =
  ## linear regression on column data:  X Y1 (Y1uncer) Y2 (Y2uncer) ...
  ## ! WIP
  var data: seq[seq[float]]
  for fn in files:
    txtcoldata.loadFile(data, fn)
    if data.len > 0 and data[0].len >= (if uncer: 3 else: 2):
      let nsamp = data[0].len
      stderr.writeLine &"{fn} ({data[0].len} points)"
      let n = (data.len - 1) div (if uncer: 2 else: 1)
      # echo n
      var a, sigmaa: seq[float]
      let m = if uncer: 2 else: 1
      for k in 0..<n:
        #echo (1+m*k, 2 + m*k)
        let res = reglen(data[0], data[1+m*k], if uncer: data[2 + m*k]  else: newSeq[float](nsamp))
        a.add res.a
        sigmaa.add res.sigmaa
      for i, aa in a:
        echo &"{aa:.8g}  +- {sigmaa[i]:.8g}"
      echo()

when isMainModule:
  import cligen
  dispatch reglencoldata
