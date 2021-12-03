
import std/[unittest, os]


import ../miscana/txtcoldata


suite "txtcoldata":
  test "simple write-load":
    let data = [@[1.2, 3.0, 4.0], @[4.0, 7.0, 8.0]]
    writeFile(data, "test", header="#test test test")
    var data2: seq[seq[float]]
    loadFile(data2, "test")
    removeFile("test")
    check data == data2

    