#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## The ``sets`` module implements an efficient hash set and ordered hash set.
##
## **Note**: The data types declared here have *value semantics*: This means
## that ``=`` performs a copy of the set.

import
  os, hashes, math

{.pragma: myShallow.}

type
  TSlotEnum = enum seEmpty, seFilled, seDeleted
  TKeyValuePair[A] = tuple[slot: TSlotEnum, key: A]
  TKeyValuePairSeq[A] = seq[TKeyValuePair[A]]
  TSet* {.final, myShallow.}[A] = object ## a generic hash set
    data: TKeyValuePairSeq[A]
    counter: int

proc len*[A](s: TSet[A]): int =
  ## returns the number of keys in `s`.
  result = s.counter

proc card*[A](s: TSet[A]): int =
  ## alias for `len`.
  result = s.counter

iterator items*[A](s: TSet[A]): A =
  ## iterates over any key in the table `t`.
  for h in 0..high(s.data):
    if s.data[h].slot == seFilled: yield s.data[h].key

const
  growthFactor = 2

proc mustRehash(length, counter: int): bool {.inline.} =
  assert(length > counter)
  result = (length * 2 < counter * 3) or (length - counter < 4)

proc nextTry(h, maxHash: THash): THash {.inline.} =
  result = ((5 * h) + 1) and maxHash

template rawGetImpl() =
  var h: THash = hash(key) and high(s.data) # start with real hash value
  while s.data[h].slot != seEmpty:
    if s.data[h].key == key and s.data[h].slot == seFilled:
      return h
    h = nextTry(h, high(s.data))
  result = -1

template rawInsertImpl() =
  var h: THash = hash(key) and high(data)
  while data[h].slot == seFilled:
    h = nextTry(h, high(data))
  data[h].key = key
  data[h].slot = seFilled

proc RawGet[A](s: TSet[A], key: A): int =
  rawGetImpl()

proc contains*[A](s: TSet[A], key: A): bool =
  ## returns true iff `key` is in `s`.
  var index = RawGet(t, key)
  result = index >= 0

proc RawInsert[A](s: var TSet[A], data: var TKeyValuePairSeq[A], key: A) =
  rawInsertImpl()

proc Enlarge[A](s: var TSet[A]) =
  var n: TKeyValuePairSeq[A]
  newSeq(n, len(s.data) * growthFactor)
  for i in countup(0, high(s.data)):
    if s.data[i].slot == seFilled: RawInsert(s, n, s.data[i].key)
  swap(s.data, n)

template inclImpl() =
  var index = RawGet(s, key)
  if index < 0:
    if mustRehash(len(s.data), s.counter): Enlarge(s)
    RawInsert(s, s.data, key)
    inc(s.counter)

template containsOrInclImpl() =
  var index = RawGet(s, key)
  if index >= 0:
    result = true
  else:
    if mustRehash(len(s.data), s.counter): Enlarge(s)
    RawInsert(s, s.data, key)
    inc(s.counter)

proc incl*[A](s: var TSet[A], key: A) =
  ## includes an element `key` in `s`.
  inclImpl()

proc excl*[A](s: var TSet[A], key: A) =
  ## excludes `key` from the set `s`.
  var index = RawGet(t, key)
  if index >= 0:
    s.data[index].slot = seDeleted
    dec(s.counter)

proc containsOrIncl*[A](s: var TSet[A], key: A): bool =
  ## returns true if `s` contains `key`, otherwise `key` is included in `s`
  ## and false is returned.
  containsOrInclImpl()

proc initSet*[A](initialSize=64): TSet[A] =
  ## creates a new hash set that is empty. `initialSize` needs to be
  ## a power of two.
  assert isPowerOfTwo(initialSize)
  result.counter = 0
  newSeq(result.data, initialSize)

proc toSet*[A](keys: openarray[A]): TSet[A] =
  ## creates a new hash set that contains the given `keys`.
  result = initSet[A](nextPowerOfTwo(keys.len+10))
  for key in items(keys): result.incl(key)

template dollarImpl(): stmt =
  result = "{"
  for key in items(s):
    if result.len > 1: result.add(", ")
    result.add($key)
  result.add("}")

proc `$`*[A](s: TSet[A]): string =
  ## The `$` operator for hash sets.
  dollarImpl()

# ------------------------------ ordered set ------------------------------

type
  TOrderedKeyValuePair[A] = tuple[
    slot: TSlotEnum, next: int, key: A]
  TOrderedKeyValuePairSeq[A] = seq[TOrderedKeyValuePair[A]]
  TOrderedSet* {.
      final, myShallow.}[A] = object ## set that remembers insertion order
    data: TOrderedKeyValuePairSeq[A]
    counter, first, last: int

proc len*[A](s: TOrderedSet[A]): int {.inline.} =
  ## returns the number of keys in `s`.
  result = t.counter

proc card*[A](s: TOrderedSet[A]): int {.inline.} =
  ## alias for `len`.
  result = t.counter

template forAllOrderedPairs(yieldStmt: stmt) =
  var h = s.first
  while h >= 0:
    var nxt = s.data[h].next
    if s.data[h].slot == seFilled: yieldStmt
    h = nxt

iterator items*[A](s: TOrderedSet[A]): A =
  ## iterates over any key in the set `s` in insertion order.
  forAllOrderedPairs:
    yield s.data[h].key

proc RawGet[A](s: TOrderedSet[A], key: A): int =
  rawGetImpl()

proc contains*[A](s: TOrderedSet[A], key: A): bool =
  ## returns true iff `key` is in `s`.
  var index = RawGet(s, key)
  result = index >= 0

proc RawInsert[A](s: var TOrderedSet[A], 
                  data: var TOrderedKeyValuePairSeq[A], key: A) =
  rawInsertImpl()
  data[h].next = -1
  if s.first < 0: s.first = h
  if s.last >= 0: data[s.last].next = h
  s.last = h

proc Enlarge[A](s: var TOrderedSet[A]) =
  var n: TOrderedKeyValuePairSeq[A]
  newSeq(n, len(s.data) * growthFactor)
  var h = s.first
  s.first = -1
  s.last = -1
  while h >= 0:
    var nxt = s.data[h].next
    if s.data[h].slot == seFilled: 
      RawInsert(s, n, s.data[h].key)
    h = nxt
  swap(s.data, n)

proc incl*[A](s: var TOrderedSet[A], key: A) =
  ## includes an element `key` in `s`.
  inclImpl()

proc containsOrIncl*[A](s: var TOrderedSet[A], key: A): bool =
  ## returns true if `s` contains `key`, otherwise `key` is included in `s`
  ## and false is returned.
  containsOrInclImpl()

proc initOrderedSet*[A](initialSize=64): TOrderedSet[A] =
  ## creates a new ordered hash set that is empty. `initialSize` needs to be
  ## a power of two.
  assert isPowerOfTwo(initialSize)
  result.counter = 0
  result.first = -1
  result.last = -1
  newSeq(result.data, initialSize)

proc toOrderedSet*[A](keys: openarray[A]): TOrderedSet[A] =
  ## creates a new ordered hash set that contains the given `keys`.
  result = initOrderedSet[A](nextPowerOfTwo(keys.len+10))
  for key in items(keys): result.incl(key)

proc `$`*[A](s: TOrderedSet[A]): string =
  ## The `$` operator for ordered hash sets.
  dollarImpl()


