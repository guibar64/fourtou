when isMainModule:
  import std/[monotimes, times]
  import ./txtcoldata
  var data: seq[seq[float]]
  let t0 = getMonoTime()
  data.loadFile("test.txt")
  echo getMonoTime()-t0
  echo data.len
  for i in 0..<3:
    for j in 0..<data.len:
      stdout.write data[j][i],'\t'
    stdout.write '\n'
  echo()
  for i in data[0].len-2..data[0].len-1:
    for j in 0..<data.len:
      stdout.write data[j][i],'\t'
    stdout.write '\n'
