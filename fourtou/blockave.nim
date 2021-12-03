
import std/[strutils, math, strformat]



proc blockAverage*(sample: openArray[float], eps: float = 1.0, printAll = false): tuple[ave, uncer, sigma: float] =
 
  let ndat = sample.len
  let eps = eps/sqrt(ndat.float)
  # var aves = newSeq[float](sample.len)
  var d = @sample
  # calculate average    
  var ave = 0.0
  for i in 0..<ndat:
    ave += d[i]
  ave /= ndat.float
  
  #  calculate errors using blocking method
  var m = ndat
  var sigma = newSeqOfCap[float](int log(m.float, 2.0))
  while m > 3:
    var sig = 0.0
    if sigma.len == 0:
      for i in 0..<m:
        d[i] -= ave
        sig += d[i]*d[i]
    else:
      var j = -1
      for i in 0..<m:
        j += 2
        d[i] = 0.5*(d[j-1]+d[j])
        sig += d[i]*d[i]
    sigma.add sqrt(sig/(float(m)*float(m-1)))
    m = m div 2

  # calculate error bars of error estimates
  var gamma = newSeq[float](sigma.len)
  m = ndat
  for n in 0..<sigma.len:
    gamma[n] = sigma[n]/sqrt(2.0*float((m-1)))
    m = m div 2
  var last = sigma.len - 1
  for n in 0..<sigma.len-1:
    if abs(sigma[n+1]-sigma[n]) <= eps*sigma[n]:
      last = n
      break
  # echo abs(sigma[n+1]-sigma[n])/sigma[n], " ",eps

  if printAll:
    for n,gam in gamma:
      stdout.write formatFloat(sigma[n],precision=8), "\t+/-\t", formatFloat(gamma[n],precision=8),"\n"
  (ave, sigma[last], sigma[0]*sqrt(float(ndat-1)))
  


when isMainModule:
  import cligen
  import ./txtcoldata, ./bincoldata


  proc blockave(files: seq[string], epsf = 1.0, nsigma=2, skip = 1, comments = {'#'}, printAll = false, total = false) =
    ## blocking method for estimating standard error of mean
    ##  (reference - Flyvbjerg and Petersen  JCP 91 (1989) 461)
    ##  copyright daresbury laboratory
    ##  author - w. smith nov 1992
    ##
    var totals: seq[tuple[ave, bsig, sig: float, nsamples: int]]
    for file in files:
      var sample: seq[seq[float]]
      if file.isBinColFile:
        bincoldata.loadFile(sample, file)
      else:
        txtcoldata.loadFile(sample, file, comments)
      if sample.len > skip:
        stderr.writeLine &"{file}: {sample[0].len} data points"
        if total and sample.len > totals.len:
          let old = totals
          totals.setLen(sample.len)
          for j in 0..<old.len:
            totals[j] = old[j]
        for j in skip..<sample.len:
          let (ave, bsig, sig) = blockAverage(sample[j], epsf, printAll)
          stdout.write &"{ave:.8g}\t±\t{2*bsig:.8g}\t(σ={sig:.8g})\n"
          let w = sample[j].len.float
          if total: totals[j] = (totals[j].ave+w*ave, totals[j].bsig+w*w*bsig*bsig, totals[j].sig+w*sig*sig, totals[j].nsamples+sample[j].len)
      else:
        stderr.writeLine &"{file}: No data ({skip} columns skipped, tune option '--skip' if necessary)"
    if total:
      for t in totals.mitems:
        if t.nsamples > 0:
          t.ave /= t.nsamples.float
          t.bsig = sqrt(t.bsig/t.nsamples.float^2)
          t.sig = sqrt(t.sig/t.nsamples.float)
      echo()
      for (ave, bsig, sig, nsamples) in totals.items:
        if nsamples > 0:
          stdout.write &"{ave:.8g}\t±\t{2*bsig:.8g}\t(σ={sig:.8g})\n"
  
  dispatch(blockave)
