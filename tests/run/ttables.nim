discard """
  output: '''true'''
  cmd: "nimrod cc --gc:none --hints:on $# $#"
"""

import hashes, tables

const
  data = {
    "34": 123456, "12": 789,
    "90": 343, "0": 34404,
    "1": 344004, "2": 344774,
    "3": 342244, "4": 3412344,
    "5": 341232144, "6": 34214544,
    "7": 3434544, "8": 344544,
    "9": 34435644, "---00": 346677844,
    "10": 34484, "11": 34474, "19": 34464,
    "20": 34454, "30": 34141244, "40": 344114,
    "50": 344490, "60": 344491, "70": 344492,
    "80": 344497}

block tableTest1:
  var t = initTable[tuple[x, y: int], string]()
  t[(0,0)] = "00"
  t[(1,0)] = "10"
  t[(0,1)] = "01"
  t[(1,1)] = "11"
  for x in 0..1:
    for y in 0..1:
      assert t[(x,y)] == $x & $y
  assert($t == 
    "{(x: 0, y: 0): 00, (x: 0, y: 1): 01, (x: 1, y: 0): 10, (x: 1, y: 1): 11}")

block tableTest2:
  var t = initTable[string, float]()
  t["test"] = 1.2345
  t["111"] = 1.000043
  t["123"] = 1.23
  t.del("111")
  
  t["012"] = 67.9
  t["123"] = 1.5 # test overwriting
  
  assert t["123"] == 1.5
  assert t["111"] == 0.0 # deleted
  assert(not hasKey(t, "111"))
  
  for key, val in items(data): t[key] = val.toFloat
  for key, val in items(data): assert t[key] == val.toFloat
  

block orderedTableTest1:
  var t = initOrderedTable[string, int](2)
  for key, val in items(data): t[key] = val
  for key, val in items(data): assert t[key] == val
  var i = 0
  # `pairs` needs to yield in insertion order:
  for key, val in pairs(t):
    assert key == data[i][0]
    assert val == data[i][1]
    inc(i)

  for key, val in mpairs(t): val = 99
  for val in mvalues(t): assert val == 99

block countTableTest1:
  var s = data.toTable
  var t = initCountTable[string]()
  for k in s.Keys: t.inc(k)
  for k in t.keys: assert t[k] == 1
  t.inc("90", 3)
  t.inc("12", 2)
  t.inc("34", 1)
  assert t.largest()[0] == "90"

  t.sort()
  var i = 0
  for k, v in t.pairs:
    case i
    of 0: assert k == "90" and v == 4
    of 1: assert k == "12" and v == 3
    of 2: assert k == "34" and v == 2
    else: break
    inc i

block SyntaxTest:
  var x = toTable[int, string]({:})

echo "true"

