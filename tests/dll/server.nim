discard """
  cmd: "nimrod cc --debuginfo --hints:on --define:useNimRtl --app:lib $# $#"
"""

type
  TNodeKind = enum nkLit, nkSub, nkAdd, nkDiv, nkMul
  TNode = object
    case k: TNodeKind
    of nkLit: x: int
    else: a, b: ref TNode

  PNode = ref TNode
    
proc newLit(x: int): PNode {.exportc: "newLit", dynlib.} =
  new(result)
  result.x = x
  
proc newOp(k: TNodeKind, a, b: PNode): PNode {.exportc: "newOp", dynlib.} =
  assert a != nil
  assert b != nil
  new(result)
  result.k = k
  result.a = a
  result.b = b
  
proc buildTree(x: int): PNode {.exportc: "buildTree", dynlib.} = 
  result = newOp(nkMul, newOp(nkAdd, newLit(x), newLit(x)), newLit(x))
