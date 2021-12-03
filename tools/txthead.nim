import std/[times, monotimes, strformat]
import ../miscana/txtcoldata

proc txthead(files: seq[string], n: int = 10) =
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

when isMainModule:
  import cligen
  dispatch(txthead)