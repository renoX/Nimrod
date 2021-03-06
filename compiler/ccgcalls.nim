#
#
#           The Nimrod Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#
#
# included from cgen.nim

proc leftAppearsOnRightSide(le, ri: PNode): bool =
  if le != nil:
    for i in 1 .. <ri.len:
      let r = ri[i]
      if isPartOf(le, r) != arNo: return true

proc hasNoInit(call: PNode): bool {.inline.} =
  result = call.sons[0].kind == nkSym and sfNoInit in call.sons[0].sym.flags

proc fixupCall(p: BProc, le, ri: PNode, d: var TLoc, pl: PRope) =
  var pl = pl
  var typ = ri.sons[0].typ # getUniqueType() is too expensive here!
  if typ.sons[0] != nil:
    if isInvalidReturnType(typ.sons[0]):
      if sonsLen(ri) > 1: app(pl, ", ")
      # beware of 'result = p(result)'. We may need to allocate a temporary:
      if d.k in {locTemp, locNone} or not leftAppearsOnRightSide(le, ri):
        # Great, we can use 'd':
        if d.k == locNone: getTemp(p, typ.sons[0], d)
        elif d.k notin {locExpr, locTemp} and not hasNoInit(ri):
          # reset before pass as 'result' var:
          resetLoc(p, d)
        app(pl, addrLoc(d))
        app(pl, ")")
        app(p.s(cpsStmts), pl)
        appf(p.s(cpsStmts), ";$n")
      else:
        var tmp: TLoc
        getTemp(p, typ.sons[0], tmp)
        app(pl, addrLoc(tmp))
        app(pl, ")")
        app(p.s(cpsStmts), pl)
        appf(p.s(cpsStmts), ";$n")
        genAssignment(p, d, tmp, {}) # no need for deep copying
    else:
      app(pl, ")")
      if d.k == locNone: getTemp(p, typ.sons[0], d)
      assert(d.t != nil)        # generate an assignment to d:
      var list: TLoc
      initLoc(list, locCall, d.t, OnUnknown)
      list.r = pl
      genAssignment(p, d, list, {}) # no need for deep copying
  else:
    app(pl, ")")
    app(p.s(cpsStmts), pl)
    appf(p.s(cpsStmts), ";$n")

proc isInCurrentFrame(p: BProc, n: PNode): bool =
  # checks if `n` is an expression that refers to the current frame;
  # this does not work reliably because of forwarding + inlining can break it
  case n.kind
  of nkSym:
    if n.sym.kind in {skVar, skResult, skTemp, skLet} and p.prc != nil:
      result = p.prc.id == n.sym.owner.id
  of nkDotExpr, nkBracketExpr:
    if skipTypes(n.sons[0].typ, abstractInst).kind notin {tyVar,tyPtr,tyRef}:
      result = isInCurrentFrame(p, n.sons[0])
  of nkHiddenStdConv, nkHiddenSubConv, nkConv:
    result = isInCurrentFrame(p, n.sons[1])
  of nkHiddenDeref, nkDerefExpr:
    # what about: var x = addr(y); callAsOpenArray(x[])?
    # *shrug* ``addr`` is unsafe anyway.
    result = false
  of nkObjUpConv, nkObjDownConv, nkCheckedFieldExpr:
    result = isInCurrentFrame(p, n.sons[0])
  else: nil

proc openArrayLoc(p: BProc, n: PNode): PRope =
  var a: TLoc
  initLocExpr(p, n, a)
  case skipTypes(a.t, abstractVar).kind
  of tyOpenArray:
    result = ropef("$1, $1Len0", [rdLoc(a)])
  of tyString, tySequence:
    if skipTypes(n.typ, abstractInst).kind == tyVar:
      result = ropef("(*$1)->data, (*$1)->$2", [a.rdLoc, lenField()])
    else:
      result = ropef("$1->data, $1->$2", [a.rdLoc, lenField()])
  of tyArray, tyArrayConstr:
    result = ropef("$1, $2", [rdLoc(a), toRope(lengthOrd(a.t))])
  else: InternalError("openArrayLoc: " & typeToString(a.t))

proc genArgStringToCString(p: BProc, 
                           n: PNode): PRope {.inline.} =
  var a: TLoc
  initLocExpr(p, n.sons[0], a)
  result = ropef("$1->data", [a.rdLoc])
  
proc genArg(p: BProc, n: PNode, param: PSym): PRope =
  var a: TLoc
  if n.kind == nkStringToCString:
    result = genArgStringToCString(p, n)
  elif skipTypes(param.typ, abstractVar).kind == tyOpenArray:
    var n = if n.kind != nkHiddenAddr: n else: n.sons[0]
    result = openArrayLoc(p, n)
  elif ccgIntroducedPtr(param):
    initLocExpr(p, n, a)
    result = addrLoc(a)
  else:
    initLocExpr(p, n, a)
    result = rdLoc(a)

proc genArgNoParam(p: BProc, n: PNode): PRope =
  var a: TLoc
  if n.kind == nkStringToCString:
    result = genArgStringToCString(p, n)
  else:
    initLocExpr(p, n, a)
    result = rdLoc(a)

proc genPrefixCall(p: BProc, le, ri: PNode, d: var TLoc) =
  var op: TLoc
  # this is a hotspot in the compiler
  initLocExpr(p, ri.sons[0], op)
  var pl = con(op.r, "(")
  var typ = ri.sons[0].typ # getUniqueType() is too expensive here!
  assert(typ.kind == tyProc)
  var length = sonsLen(ri)
  for i in countup(1, length - 1):
    assert(sonsLen(typ) == sonsLen(typ.n))
    if ri.sons[i].typ.isCompileTimeOnly: continue
    if i < sonsLen(typ):
      assert(typ.n.sons[i].kind == nkSym)
      app(pl, genArg(p, ri.sons[i], typ.n.sons[i].sym))
    else:
      app(pl, genArgNoParam(p, ri.sons[i]))
    if i < length - 1: app(pl, ", ")
  fixupCall(p, le, ri, d, pl)

proc genClosureCall(p: BProc, le, ri: PNode, d: var TLoc) =

  proc getRawProcType(p: BProc, t: PType): PRope =
    result = getClosureType(p.module, t, clHalf)

  proc addComma(r: PRope): PRope =
    result = if r == nil: r else: con(r, ", ")

  const CallPattern = "$1.ClEnv? $1.ClPrc($3$1.ClEnv) : (($4)($1.ClPrc))($2)"
  var op: TLoc
  initLocExpr(p, ri.sons[0], op)
  var pl: PRope
  var typ = ri.sons[0].typ
  assert(typ.kind == tyProc)
  var length = sonsLen(ri)
  for i in countup(1, length - 1):
    assert(sonsLen(typ) == sonsLen(typ.n))
    if i < sonsLen(typ):
      assert(typ.n.sons[i].kind == nkSym)
      app(pl, genArg(p, ri.sons[i], typ.n.sons[i].sym))
    else:
      app(pl, genArgNoParam(p, ri.sons[i]))
    if i < length - 1: app(pl, ", ")
  
  template genCallPattern =
    appf(p.s(cpsStmts), CallPattern, op.r, pl, pl.addComma, rawProc)

  let rawProc = getRawProcType(p, typ)
  if typ.sons[0] != nil:
    if isInvalidReturnType(typ.sons[0]):
      if sonsLen(ri) > 1: app(pl, ", ")
      # beware of 'result = p(result)'. We may need to allocate a temporary:
      if d.k in {locTemp, locNone} or not leftAppearsOnRightSide(le, ri):
        # Great, we can use 'd':
        if d.k == locNone: getTemp(p, typ.sons[0], d)
        elif d.k notin {locExpr, locTemp} and not hasNoInit(ri):
          # reset before pass as 'result' var:
          resetLoc(p, d)
        app(pl, addrLoc(d))
        genCallPattern()
        appf(p.s(cpsStmts), ";$n")
      else:
        var tmp: TLoc
        getTemp(p, typ.sons[0], tmp)
        app(pl, addrLoc(tmp))        
        genCallPattern()
        appf(p.s(cpsStmts), ";$n")
        genAssignment(p, d, tmp, {}) # no need for deep copying
    else:
      if d.k == locNone: getTemp(p, typ.sons[0], d)
      assert(d.t != nil)        # generate an assignment to d:
      var list: TLoc
      initLoc(list, locCall, d.t, OnUnknown)
      list.r = ropef(CallPattern, op.r, pl, pl.addComma, rawProc)
      genAssignment(p, d, list, {}) # no need for deep copying
  else:
    genCallPattern()
    appf(p.s(cpsStmts), ";$n")
  
proc genInfixCall(p: BProc, le, ri: PNode, d: var TLoc) =
  var op, a: TLoc
  initLocExpr(p, ri.sons[0], op)
  var pl: PRope = nil
  var typ = ri.sons[0].typ # getUniqueType() is too expensive here!
  assert(typ.kind == tyProc)
  var length = sonsLen(ri)
  assert(sonsLen(typ) == sonsLen(typ.n))
  
  var param = typ.n.sons[1].sym
  app(pl, genArg(p, ri.sons[1], param))
  
  if skipTypes(param.typ, {tyGenericInst}).kind == tyPtr: app(pl, "->")
  else: app(pl, ".")
  app(pl, op.r)
  app(pl, "(")
  for i in countup(2, length - 1):
    assert(sonsLen(typ) == sonsLen(typ.n))
    if i < sonsLen(typ):
      assert(typ.n.sons[i].kind == nkSym)
      app(pl, genArg(p, ri.sons[i], typ.n.sons[i].sym))
    else:
      app(pl, genArgNoParam(p, ri.sons[i]))
    if i < length - 1: app(pl, ", ")
  fixupCall(p, le, ri, d, pl)

proc genNamedParamCall(p: BProc, ri: PNode, d: var TLoc) =
  # generates a crappy ObjC call
  var op, a: TLoc
  initLocExpr(p, ri.sons[0], op)
  var pl = toRope"["
  var typ = ri.sons[0].typ # getUniqueType() is too expensive here!
  assert(typ.kind == tyProc)
  var length = sonsLen(ri)
  assert(sonsLen(typ) == sonsLen(typ.n))
  
  if length > 1:
    app(pl, genArg(p, ri.sons[1], typ.n.sons[1].sym))
    app(pl, " ")
  app(pl, op.r)
  if length > 2:
    app(pl, ": ")
    app(pl, genArg(p, ri.sons[2], typ.n.sons[2].sym))
  for i in countup(3, length-1):
    assert(sonsLen(typ) == sonsLen(typ.n))
    if i >= sonsLen(typ):
      InternalError(ri.info, "varargs for objective C method?")
    assert(typ.n.sons[i].kind == nkSym)
    var param = typ.n.sons[i].sym
    app(pl, " ")
    app(pl, param.name.s)
    app(pl, ": ")
    app(pl, genArg(p, ri.sons[i], param))
  if typ.sons[0] != nil:
    if isInvalidReturnType(typ.sons[0]):
      if sonsLen(ri) > 1: app(pl, " ")
      # beware of 'result = p(result)'. We always allocate a temporary:
      if d.k in {locTemp, locNone}:
        # We already got a temp. Great, special case it:
        if d.k == locNone: getTemp(p, typ.sons[0], d)
        app(pl, "Result: ")
        app(pl, addrLoc(d))
        app(pl, "]")
        app(p.s(cpsStmts), pl)
        appf(p.s(cpsStmts), ";$n")
      else:
        var tmp: TLoc
        getTemp(p, typ.sons[0], tmp)
        app(pl, addrLoc(tmp))
        app(pl, "]")
        app(p.s(cpsStmts), pl)
        appf(p.s(cpsStmts), ";$n")
        genAssignment(p, d, tmp, {}) # no need for deep copying
    else:
      app(pl, "]")
      if d.k == locNone: getTemp(p, typ.sons[0], d)
      assert(d.t != nil)        # generate an assignment to d:
      var list: TLoc
      initLoc(list, locCall, nil, OnUnknown)
      list.r = pl
      genAssignment(p, d, list, {}) # no need for deep copying
  else:
    app(pl, "]")
    app(p.s(cpsStmts), pl)
    appf(p.s(cpsStmts), ";$n")

proc genCall(p: BProc, e: PNode, d: var TLoc) =
  if e.sons[0].typ.callConv == ccClosure:
    genClosureCall(p, nil, e, d)
  elif e.sons[0].kind == nkSym and sfInfixCall in e.sons[0].sym.flags and
      e.len >= 2:
    genInfixCall(p, nil, e, d)
  elif e.sons[0].kind == nkSym and sfNamedParamCall in e.sons[0].sym.flags:
    genNamedParamCall(p, e, d)
  else:
    genPrefixCall(p, nil, e, d)
  when false:
    if d.s == onStack and containsGarbageCollectedRef(d.t): keepAlive(p, d)

proc genAsgnCall(p: BProc, le, ri: PNode, d: var TLoc) =
  if ri.sons[0].typ.callConv == ccClosure:
    genClosureCall(p, le, ri, d)
  elif ri.sons[0].kind == nkSym and sfInfixCall in ri.sons[0].sym.flags and
      ri.len >= 2:
    genInfixCall(p, le, ri, d)
  elif ri.sons[0].kind == nkSym and sfNamedParamCall in ri.sons[0].sym.flags:
    genNamedParamCall(p, ri, d)
  else:
    genPrefixCall(p, le, ri, d)
  when false:
    if d.s == onStack and containsGarbageCollectedRef(d.t): keepAlive(p, d)

