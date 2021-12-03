import std/[typetraits, memfiles, endians]

const
  magic = 0x001F1BC0'u32
  endMagic = 0xC01B1F00'u32
type
  Meta = object
    size: int64

  Header = object
    ndata: int64


template `+!`(p: pointer, off: int): pointer = cast[pointer](cast[ByteAddress](p)+ByteAddress(off))

proc writeFile*[T](data: openArray[seq[T]], fileName: string) =
  assert supportsCopyMem(T)
  var dataLen = 0
  for i in 0..<data.len:
    datalen += data[i].len
  var f = memfiles.open(fileName, mode = fmWrite, newFileSize = sizeof(magic)+sizeof(int64)+sizeof(Meta)*data.len+sizeof(T)*dataLen)
  var u = magic
  copyMem(f.mem, addr u, sizeof(magic))
  var pos = sizeof(magic)
  template writef(p, size) = 
    copyMem(f.mem +! pos, p, size)
    pos += size

  var ndata: int64 = data.len
  writef(addr ndata, sizeof(int64))

  for i in 0..<data.len:
    var dsize: int64 = data[i].len 
    writef(addr dsize, sizeof(int64))
    writef(unsafeaddr data[i][0], sizeof(T)*data[i].len)
  
  
  f.close()

proc isBinColFile*(fileName: string): bool =
  var f = system.open(fileName, fmRead)
  var u: uint32 
  let nr = f.readBuffer(addr u, sizeof(u))
  result = nr == 4 and (u == magic or u == endMagic)

proc loadFile*[T](data: var seq[seq[T]], fileName: string) =
  assert supportsCopyMem(T)
  var dataLen = 0
  for i in 0..<data.len:
    datalen += data[i].len
  var f = memfiles.open(fileName, mode = fmRead)
  var pos = 0
  
  template readf(p, size) = 
    copyMem(p, f.mem +! pos, size)
    pos += size
  template readfOE(p, size) =
    var x: typeof(p[]) 
    copyMem(addr x, f.mem +! pos, size)
    when sizeof(p[]) == 8:
      swapEndian64(p, addr x)
    elif sizeof(p[]) == 4:
      swapEndian32(p, addr x)
    elif sizeof(p[]) == 2:
      swapEndian16(p, addr x)
    else:
      p[] = x
    pos += size
  var u: uint32
  readf(addr u, sizeof(u))
  if u == magic or u == endMagic:
    var oppEndian = u == endMagic 
    template readfIfOE(p, size) =
      if oppEndian: readfOE(p, size)
      else: readf(p, size)

    var ndata: int64
    readfIfOE(addr ndata, sizeof(ndata))
    data.setLen(ndata.int)    

    if oppEndian:
      for i in 0..<data.len:
        var dsize: int64 #= data[i].len 
        readfOE(addr dsize, sizeof(int64))
        data[i].setLen(dsize.int)
        for j in 0..<data.len:
          readfOE(unsafeaddr data[i][j], sizeof(T))
    else:
      for i in 0..<data.len:
        var dsize: int64 #= data[i].len 
        readf(addr dsize, sizeof(int64))
        data[i].setLen(dsize.int)
        readf(unsafeaddr data[i][0], sizeof(T)*dsize.int)
      
  
  f.close()


when isMainModule:
  import std/[os]
  let data = [@[1.2, 3.0, 4.0], @[4.0, 7.0, 8.0]]
  writeFile(data, "test")
  var data2: seq[seq[float]]
  loadFile(data2, "test")
  removeFile("test")
  doAssert data == data2

