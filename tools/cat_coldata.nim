import std/[strformat]
import ../miscana/[bincoldata, txtcoldata]

proc cat_coldata(files: seq[string], output: string, binary_output = true) =
  # Columnar text data to bin format
  var data: seq[seq[float]]
  var first = true
  for file in files:
    var ldat: seq[seq[float]]
    if file.isBinColFile:
      bincoldata.loadFile(ldat, file)
    else:
      txtcoldata.loadFile(ldat, file)
    if first:
      data.setLen(ldat.len)
      first = false
    if ldat.len > 0:
      for i in 0..<data.len:
        if i < ldat.len:
          data[i].add ldat[i]
        else:
          data[i].setLen(data[i].len+ldat[0].len)
    if binary_output:
      bincoldata.writeFile(data, output)
    else:
      txtcoldata.writeFile(data, output)

when isMainModule:
  import cligen
  dispatch(cat_coldata)
  