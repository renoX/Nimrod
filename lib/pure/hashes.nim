#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements efficient computations of hash values for diverse
## Nimrod types.

import 
  strutils

type 
  THash* = int ## a hash value; hash tables using these values should 
               ## always have a size of a power of two and can use the ``and``
               ## operator instead of ``mod`` for truncation of the hash value.

proc `!&`*(h: THash, val: int): THash {.inline.} = 
  ## mixes a hash value `h` with `val` to produce a new hash value. This is
  ## only needed if you need to implement a hash proc for a new datatype.
  result = h +% val
  result = result +% result shl 10
  result = result xor (result shr 6)

proc `!$`*(h: THash): THash {.inline.} = 
  ## finishes the computation of the hash value. This is
  ## only needed if you need to implement a hash proc for a new datatype.
  result = h +% h shl 3
  result = result xor (result shr 11)
  result = result +% result shl 15

proc hashData*(Data: Pointer, Size: int): THash = 
  ## hashes an array of bytes of size `size`
  var h: THash = 0
  var p = cast[cstring](Data)
  var i = 0
  var s = size
  while s > 0: 
    h = h !& ord(p[i])
    Inc(i)
    Dec(s)
  result = !$h

proc hash*(x: Pointer): THash {.inline.} = 
  ## efficient hashing of pointers
  result = (cast[THash](x)) shr 3 # skip the alignment
  
proc hash*(x: int): THash {.inline.} = 
  ## efficient hashing of integers
  result = x

proc hash*(x: int64): THash {.inline.} = 
  ## efficient hashing of integers
  result = toU32(x)

proc hash*(x: char): THash {.inline.} = 
  ## efficient hashing of characters
  result = ord(x)

proc hash*(x: string): THash = 
  ## efficient hashing of strings
  var h: THash = 0
  for i in 0..x.len-1: 
    h = h !& ord(x[i])
  result = !$h
  
proc hashIgnoreStyle*(x: string): THash = 
  ## efficient hashing of strings; style is ignored
  var h: THash = 0
  for i in 0..x.len-1: 
    var c = x[i]
    if c == '_': 
      continue                # skip _
    if c in {'A'..'Z'}: 
      c = chr(ord(c) + (ord('a') - ord('A'))) # toLower()
    h = h !& ord(c)
  result = !$h

proc hashIgnoreCase*(x: string): THash = 
  ## efficient hashing of strings; case is ignored
  var h: THash = 0
  for i in 0..x.len-1: 
    var c = x[i]
    if c in {'A'..'Z'}: 
      c = chr(ord(c) + (ord('a') - ord('A'))) # toLower()
    h = h !& ord(c)
  result = !$h
  
proc hash*[T: tuple](x: T): THash = 
  ## efficient hashing of tuples.
  for f in fields(x):
    result = result !& hash(f)
  result = !$result

