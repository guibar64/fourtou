import std/[times, monotimes, strformat]
import ../fourtou/bincoldata

from ../fourtou/txtcoldata import nil

proc head(files: seq[string], n: int = 10) =
  var data: seq[seq[float]]
  for file in files:
    if files.len > 1:
      stdout.writeLine "==> ",file," <==" 

    let t0 = getMonoTime()
    loadFile(data, file)
    let t1 = getMonoTime()
    stderr.writeLine t1-t0
    for i in 0..<min(n, if data.len <= 0: 0 else: data[0].len):
      for j in 0..<data.len-1:
        stdout.write &"{data[j][i]:.8g}\t"
      stdout.write(&"{data[^1][i]:.8g}\p")
    if files.len > 1:
      stdout.write("\p")

proc tail(files: seq[string], n: int = 10) =
  var data: seq[seq[float]]
  for file in files:
    if files.len > 1:
      stdout.writeLine "==> ",file," <==" 

    loadFile(data, file)
    let rlen = (if data.len <= 0: 0 else: data[0].len)
    for i in max(0, rlen-n)..<rlen:
      for j in 0..<data.len-1:
        stdout.write &"{data[j][i]:.8g}\t"
      stdout.write(&"{data[^1][i]:.8g}\p")
    if files.len > 1:
      stdout.write("\p")

proc totxt(files: seq[string], output: string, skip = 1, start = 0, `end` = -1) =
  var data: seq[seq[float]]
  if files.len > 0:
    let file = files[0]
    loadFile(data, file)
    if data.len > 0:
      let endl = if `end` < 0: data[0].len else: `end`
      var temp = newSeqOfCap[float](data[0].len)
      if skip >= 1 or start != 0 or endl < data[0].len:
        temp.setLen(0)
        for j, _ in data.pairs:
          for i in countup(start, endl, skip):
            temp.add data[j][i]
          data[j] = temp
      txtcoldata.writeFile(data, output)

proc dims(files: seq[string]) =
  var data: seq[seq[float]]
  for file in files:
    loadFile(data, file)
    let
      nrows = if data.len > 0: data[0].len else: 0
    echo &"""cols = {data.len} rows = {nrows}"""


proc toagr(files: seq[string], output: string, set_type: string, `block`:seq[string] = @[]) =
  quit "Error: TODO"
  var data: seq[seq[float]]
  if files.len > 0:
    let file = files[0]
    loadFile(data, file)
    var blks: seq[(float, float, float, float)] # xy[dx][dy]
    for b in `block`:
      discard #TODO

  var f = open(output, fmWrite)
  f.write("# Grace project file\n#\n")

  f.close()
  


when isMainModule:
  import cligen
  dispatchMulti([head], [tail], [dims],[totxt])
  