import std/[parseutils, strformat]

from std/strutils import WhiteSpace

proc c_strtod(buf: cstring, endptr: ptr cstring): cdouble {.
  importc: "strtod", header: "<stdlib.h>", noSideEffect.}


const
  IdentChars = {'a'..'z', 'A'..'Z', '0'..'9', '_'}
  powtens =  [1e0, 1e1, 1e2, 1e3, 1e4, 1e5, 1e6, 1e7, 1e8, 1e9,
              1e10, 1e11, 1e12, 1e13, 1e14, 1e15, 1e16, 1e17, 1e18, 1e19,
              1e20, 1e21, 1e22]


proc nimParseBiggestFloat(s: openArray[char], number: var BiggestFloat,
                          start = 0): int =
  # This routine attempt to parse float that can parsed quickly.
  # i.e. whose integer part can fit inside a 53bits integer.
  # their real exponent must also be <= 22. If the float doesn't follow
  # these restrictions, transform the float into this form:
  #  INTEGER * 10 ^ exponent and leave the work to standard `strtod()`.
  # This avoid the problems of decimal character portability.
  # see: http://www.exploringbinary.com/fast-path-decimal-to-floating-point-conversion/
  var
    i = start
    sign = 1.0
    kdigits, fdigits = 0
    exponent = 0
    integer = uint64(0)
    fracExponent = 0
    expSign = 1
    firstDigit = -1
    hasSign = false

  # Sign?
  if i < s.len and (s[i] == '+' or s[i] == '-'):
    hasSign = true
    if s[i] == '-':
      sign = -1.0
    inc(i)

  # NaN?
  if i+2 < s.len and (s[i] == 'N' or s[i] == 'n'):
    if s[i+1] == 'A' or s[i+1] == 'a':
      if s[i+2] == 'N' or s[i+2] == 'n':
        if i+3 >= s.len or s[i+3] notin IdentChars:
          number = NaN
          return i+3 - start
    return 0

  # Inf?
  if i+2 < s.len and (s[i] == 'I' or s[i] == 'i'):
    if s[i+1] == 'N' or s[i+1] == 'n':
      if s[i+2] == 'F' or s[i+2] == 'f':
        if i+3 >= s.len or s[i+3] notin IdentChars:
          number = Inf*sign
          return i+3 - start
    return 0

  if i < s.len and s[i] in {'0'..'9'}:
    firstDigit = (s[i].ord - '0'.ord)
  # Integer part?
  while i < s.len and s[i] in {'0'..'9'}:
    inc(kdigits)
    integer = integer * 10'u64 + (s[i].ord - '0'.ord).uint64
    inc(i)
    while i < s.len and s[i] == '_': inc(i)

  # Fractional part?
  if i < s.len and s[i] == '.':
    inc(i)
    # if no integer part, Skip leading zeros
    if kdigits <= 0:
      while i < s.len and s[i] == '0':
        inc(fracExponent)
        inc(i)
        while i < s.len and s[i] == '_': inc(i)

    if firstDigit == -1 and i < s.len and s[i] in {'0'..'9'}:
      firstDigit = (s[i].ord - '0'.ord)
    # get fractional part
    while i < s.len and s[i] in {'0'..'9'}:
      inc(fdigits)
      inc(fracExponent)
      integer = integer * 10'u64 + (s[i].ord - '0'.ord).uint64
      inc(i)
      while i < s.len and s[i] == '_': inc(i)

  # if has no digits: return error
  if kdigits + fdigits <= 0 and
     (i == start or # no char consumed (empty string).
     (i == start + 1 and hasSign)): # or only '+' or '-
    return 0

  if i+1 < s.len and s[i] in {'e', 'E'}:
    inc(i)
    if s[i] == '+' or s[i] == '-':
      if s[i] == '-':
        expSign = -1

      inc(i)
    if s[i] notin {'0'..'9'}:
      return 0
    while i < s.len and s[i] in {'0'..'9'}:
      exponent = exponent * 10 + (ord(s[i]) - ord('0'))
      inc(i)
      while i < s.len and s[i] == '_': inc(i) # underscores are allowed and ignored

  var realExponent = expSign*exponent - fracExponent
  let expNegative = realExponent < 0
  var absExponent = abs(realExponent)

  # if exponent greater than can be represented: +/- zero or infinity
  if absExponent > 999:
    if expNegative:
      number = 0.0*sign
    else:
      number = Inf*sign
    return i - start

  # if integer is representable in 53 bits:  fast path
  # max fast path integer is  1<<53 - 1 or  8999999999999999 (16 digits)
  let digits = kdigits + fdigits
  if digits <= 15 or (digits <= 16 and firstDigit <= 8):
    # max float power of ten with set bits above the 53th bit is 10^22
    if absExponent <= 22:
      if expNegative:
        number = sign * integer.float / powtens[absExponent]
      else:
        number = sign * integer.float * powtens[absExponent]
      return i - start

    # if exponent is greater try to fit extra exponent above 22 by multiplying
    # integer part is there is space left.
    let slop = 15 - kdigits - fdigits
    if absExponent <= 22 + slop and not expNegative:
      number = sign * integer.float * powtens[slop] * powtens[absExponent-slop]
      return i - start

  # if failed: slow path with strtod.
  var t: array[500, char] # flaviu says: 325 is the longest reasonable literal
  var ti = 0
  let maxlen = t.high - "e+000".len # reserve enough space for exponent

  result = i - start
  i = start
  # re-parse without error checking, any error should be handled by the code above.
  if i < s.len and s[i] == '.': i.inc
  while i < s.len and s[i] in {'0'..'9','+','-'}:
    if ti < maxlen:
      t[ti] = s[i]; inc(ti)
    inc(i)
    while i < s.len and s[i] in {'.', '_'}: # skip underscore and decimal point
      inc(i)

  # insert exponent
  t[ti] = 'E'
  inc(ti)
  t[ti] = if expNegative: '-' else: '+'
  inc(ti, 4)

  # insert adjusted exponent
  t[ti-1] = ('0'.ord + absExponent mod 10).char
  absExponent = absExponent div 10
  t[ti-2] = ('0'.ord + absExponent mod 10).char
  absExponent = absExponent div 10
  t[ti-3] = ('0'.ord + absExponent mod 10).char

  number = c_strtod(cast[cstring](addr t[0]), nil)

proc integerOutOfRangeError() {.noinline.} =
  raise newException(ValueError, "Parsed integer outside of valid range")

proc rawParseInt(s: openArray[char], b: var BiggestInt, start = 0): int =
  var
    sign: BiggestInt = -1
    i = start
  if i < s.len:
    if s[i] == '+': inc(i)
    elif s[i] == '-':
      inc(i)
      sign = 1
  if i < s.len and s[i] in {'0'..'9'}:
    b = 0
    while i < s.len and s[i] in {'0'..'9'}:
      let c = ord(s[i]) - ord('0')
      if b >= (low(BiggestInt) + c) div 10:
        b = b * 10 - c
      else:
        integerOutOfRangeError()
      inc(i)
      while i < s.len and s[i] == '_': inc(i) # underscores are allowed and ignored
    if sign == -1 and b == low(BiggestInt):
      integerOutOfRangeError()
    else:
      b = b * sign
      result = i - start

proc rawParseUInt(s: openArray[char], b: var BiggestUInt, start = 0): int =
  var
    res = 0.BiggestUInt
    prev = 0.BiggestUInt
    i = start
  if i < s.len - 1 and s[i] == '-' and s[i + 1] in {'0'..'9'}:
    integerOutOfRangeError()
  if i < s.len and s[i] == '+': inc(i) # Allow
  if i < s.len and s[i] in {'0'..'9'}:
    b = 0
    while i < s.len and s[i] in {'0'..'9'}:
      prev = res
      res = res * 10 + (ord(s[i]) - ord('0')).BiggestUInt
      if prev > res:
        integerOutOfRangeError()
      inc(i)
      while i < s.len and s[i] == '_': inc(i) # underscores are allowed and ignored
    b = res
    result = i - start


proc parse[T: SomeFloat](x: var T, s: openArray[char], start: int): int {.inline.} =
  var f: cdouble
  result = nimParseBiggestFloat(s, f, start)
  x = f

proc parse[T: int|int32|int64|int16|int8](x: var T, s: openArray[char], start: int): int {.inline.} =
  var i: BiggestInt
  result = rawParseInt(s, x, start)
  x = i

proc parse[T: uint|uint32|uint64|uint16|uint8](x: var T, s: string, start: int): int {.inline.} =
  var u: uint
  result = rawParseUInt(s, u, start)
  x = u



when defined(noMemFile):
  proc loadFile*[T](result: var seq[seq[T]], fileName: string, comments={'#'}) =
    mixin parse

    var f = open(fileName, fmRead)
    var line: string
    while f.readLine(line) and line.len > 0 and line[0] in comments:
      discard

    var pos = 0
    template skip(chars: untyped): untyped =
      while pos < line.len and line[pos] in chars:
        inc pos

    if true:
      var ncols: int
      while pos < line.len:
        skip({' ', '\t', '\f'})
        let oldpos = pos
        while pos < line.len and line[pos] notin {' ', '\t', '\f', '\c','\n'}:
          inc pos
        if pos > oldpos: inc ncols
        if pos >= line.len or line[pos] in {'\n', '\c'}:
          break
      
      result.setLen(ncols)
      var nlines = 0
      var x: T
      while true:
        ncols = 0
        pos = 0
        skip({' ', '\t', '\f'})
        while pos < line.len:
          let oldpos = pos
          pos += parse(x, line,  start=pos)
          if pos > oldpos:
            result[ncols].setLen(nlines+1)
            result[ncols][nlines] = x
            inc ncols
          skip({' ', '\t', '\f'})
          if pos >= line.len or line[pos] in {'\n', '\c'}:
            break

        if not f.readLine(line): break
        inc nlines

    f.close()
else:
  import std/memfiles

  type
    Error = object
      
      msg: string

  proc parseChunk[T](data: var seq[seq[float]], line: ptr UncheckedArray[T], start: int, last: int, lineNum, cols: int, comments: set[char]): (int, int) =
    var pos = start
    let lim = last+1
    template skip(chars: untyped): untyped =
      while pos < lim and line[pos] in chars:
        inc pos
    template until(chars: untyped): untyped =
      while pos < lim and line[pos] notin chars:
        inc pos
    var ncols = 0
    var nlines = lineNum
    var ndatlines = 1 + data[0].len
    var x: float
    var pfault = -1
    while pos <= last:
      let oldpos = pos
      if line[pos] in comments:
        until({'\n','\c'})
      else:     
        pos += parse(x, line.toOpenArray(pos, lim), 0)
        if pos > oldpos:
          if ncols < cols:
            data[ncols].setLen(ndatlines)
            data[ncols][ndatlines-1] = x
          inc ncols
        else:
          pfault = pos
          break
        skip({' ', '\t', '\f'})
      if line[pos] in {'\n', '\c'}:
        skip({'\c','\n'})
        if line[pos] notin comments:
          inc ndatlines
        inc nlines 
        ncols = 0
    result = (nlines, pfault)
  
  proc loadFile*[T](result: var seq[seq[T]], fileName: string, comments={'#'}) =

    var f = memfiles.open(fileName, mode = fmRead)
    var pos = 0
    let line = cast[ptr UncheckedArray[char]](f.mem)
    template len(line: ptr UncheckedArray[char]): int = f.size
    template skip(chars: untyped): untyped =
      while pos < f.size and line[pos] in chars:
        inc pos    
    template until(chars: untyped): untyped =
      while pos < f.size and line[pos] notin chars:
        inc pos    

    var nlines = 0
    while pos < f.size and line[pos] in comments:
      until({'\n','\c'})
      inc nlines
      inc pos
      skip({'\n','\c'})
      
    if pos < f.size:
      var ncols: int
      let oldpos = pos
      while pos < line.len:
        skip({' ', '\t', '\f'})
        let oldpos = pos
        while pos < line.len and line[pos] notin {' ', '\t', '\f', '\c','\n'}:
          inc pos
        if pos > oldpos: inc ncols
        if pos >= line.len or line[pos] in {'\n', '\c'}:
          break

      if ncols > 0:
        result.setLen(ncols)
        var ndatlines = 1
        ncols = 0
        pos = oldpos
        skip({' ', '\t', '\f','\n','\c'})
        var x: T
        var chunkPos = pos
        while pos < line.len:
          skip({' ', '\t', '\f'})
          let oldpos = pos
          if line[pos] in comments:
            until({'\n','\c'})
          else :
            pos += parse(x, line.toOpenArray(pos, line.len), 0)
            if pos > oldpos:
              result[ncols].setLen(ndatlines)
              result[ncols][ndatlines-1] = x
              inc ncols
            else:
              var val: string = $line[pos]
              while val.len < 20 and pos < f.size and line[pos] notin WhiteSpace:
                val.add line[pos]
                inc pos
              raise newException(ValueError, &"{fileName}:{nlines}: Invalid float '{val}'")
            skip({' ', '\t', '\f'})
          if line[pos] in {'\n', '\c'}:
            skip({'\c','\n'})
            if line[pos] notin comments:
              inc ndatlines
            inc nlines  
            ncols = 0

    f.close()

  
proc writeFile*[T](data: openArray[seq[T]], fileName: string, sep='\t', header = "", format = "") =
  var f = system.open(fileName, fmWrite)

  let fmt = 
    when T is SomeFloat: 
      if format.len == 0: ".7e" else: format
    else:
      format
  if header.len > 0:
    f.write(header, '\n')
  var line: string
  if data.len > 0:
    for i in 0..<data[0].len:
      line.setLen(0)
      for j in 0..<data.len:
        formatValue(line, data[j][i], fmt)
        line.add(if j == data.len-1: '\n' else: sep)
      f.write line
  f.close()


proc writeFile*[T](x: openArray[T], data: openArray[seq[T]], fileName: string, sep='\t', header = "", format = "") =
  var f = system.open(fileName, fmWrite)

  let fmt = 
    when T is SomeFloat: 
      if format.len == 0: ".7e" else: format
    else:
      format
  if header.len > 0:
    f.write(header, '\n')
  var line: string
  if data.len > 0:
    assert x.len == data[0].len
    for i in 0..<data[0].len:
      line.setLen(0)
      formatValue(line, x[i], fmt)
      line.add sep
      for j in 0..<data.len:
        formatValue(line, data[j][i], fmt)
        line.add(if j == data.len-1: '\n' else: sep)
      f.write line
  f.close()

  