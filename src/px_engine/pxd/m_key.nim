import std/hashes


type KeyIdKind = enum
  KTag,
  KId


type KeyId* = object
  case kind: KeyIdKind
    of KTag:
      tag*: string
    of KId:
      id*:  int


type AnyKeyId* = string | int | enum


proc hash*(key: KeyId): Hash {.inline.} =
  case key.kind:
  of KTag:
    result = hash(key.tag)
  of KId:
    result = hash(key.id)


proc `==`*(a: KeyId, b: KeyId): bool {.inline.} =
  if a.kind != b.kind:
    return false
  case a.kind:
  of KTag:
    return a.tag == b.tag
  of KId:
    return a.id == b.id


proc toKeyId*(tag: string): KeyId =
  KeyId(kind: KTag, tag: tag)


proc toKeyId*(id: int): KeyId = 
  KeyId(kind: KId, id: id)


proc toKeyId*(id: enum): KeyId = 
  KeyId(kind: KId, id: id.int)


proc toString*(key: KeyId): string =
  key.tag


converter toOrdinal*(t: KeyId): int =
  t.id


import std/macrocache
const nextKeyID* = CacheCounter"Pxd.KeyId"


proc Next*(api: typedesc[KeyId]): KeyId {.compileTime.} =
  result = KeyId(kind: KId, id: nextKeyId.value)
  inc nextKeyID


proc Next*(api: typedesc[KeyId], value: int): KeyId {.compileTime.} =
  inc nextKeyId, value - nextKeyId.value
  result = KeyId(kind: KId, id: nextKeyId.value)
  inc nextKeyID