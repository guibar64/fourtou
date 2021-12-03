

import random, strformat


randomize(46387268236)
var data = newSeq[seq[float]](10)
for j in 1..10: data[j-1].setLen(1000000)
for i in 1..1000000:
  for j in 1..10:
    data[j-1][i-1] = (rand(-1.0e4..1.0e4))

block:
  var f = open("test_data.txt", fmWrite)
  for i in 1..1000000:
    for j in 1..10:
      f.write(&"{data[j-1][i-1]:.7e}")
      f.write(if j==10: '\n' else: ' ')
  f.close()


import ./bincoldata

block:
  writeFile(data, "test_data.bin")
