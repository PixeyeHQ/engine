import std/strutils
import std/strformat
import std/hashes
import px_engine/pxd/api
import px_engine/pxd/m_debug
export hashes


#------------------------------------------------------------------------------------------
# @api mem pool
#------------------------------------------------------------------------------------------
type Int     = uint64


const OBJ_BIT_LO:  Int = 1 shl 32 - 1
const OBJ_BIT_HI:  Int = 1 shl 32
const OBJ_VER_MAX: Int = 1 shl 32 - 1
const OBJ_ID_MAX:  int = int(OBJ_BIT_LO)
const OBJ_HANDLE_NIL: Int = high(Int)


type
  Slot[T,H] = object
    handle*: H
    data*:   T
  Pool[T,H] = ref object
    slots*:        seq[Slot[T,H]]
    spareHandles*: seq[Int]
    count*:        int


proc newMemPool*(T: typedesc, H: typedesc, presize: int = 4): Pool[T,H] =
  new(result)
  result.slots        = newSeq[Slot[T,H]](presize)
  result.spareHandles = newSeq[Int](presize)
  result.count        = 0
  var index = result.spareHandles.len
  while 0 < index:
    dec index
    result.spareHandles[index] = Int(result.spareHandles.high-index)
  for slot in result.slots.mitems:
    slot.data   = T()
    slot.handle = H(OBJ_HANDLE_NIL)


iterator mitems*[T,H](pool: var Pool[T,H]): var T =
  var index = pool.slots.len
  while 0 < index:
    dec index
    let handle = (pool.slots[index].handle)
    if handle.alive:
      yield pool.slots[index].data


iterator handles*[T,H](pool: var Pool[T,H]): H =
  var index = pool.slots.len
  while 0 < index:
    dec index
    let handle = H(pool.slots[index].handle)
    if handle.alive:
      yield handle


template GEN_MEM_POOL*(T: typedesc, H: typedesc, defaultSize: static int = 4) =
  {.push checks: off.}
  var poolDefault     = newMemPool(T,H,defaultSize)
  var pool {.cursor.} = poolDefault
  type ObjectType = typedesc[T]
  type HandleType = H
  type HandleMeta = distinct H

  template onDropNotify(handle: HandleType) =
    when compiles(onDrop(handle)):
      onDrop(handle)


  template onMakeNotify(handle: HandleType) =
    when compiles(onMake(handle)):
      onMake(handle)


  proc `==` (a, b: HandleType) : bool {.borrow.}
  proc hash (x: HandleType): Hash {.borrow.}


  proc version*(handle: HandleType): Int {.inline.} =
    Int((Int(handle)-(Int(handle) and OBJ_BIT_LO)) div (OBJ_BIT_HI))


  proc id*(handle: HandleType): Int {.inline.} =
    Int(Int(handle) and OBJ_BIT_LO)


  proc alive*(handle: HandleType): bool {.inline.} =
    int(handle.id) < pool.slots.len and uint64(pool.slots[handle.id].handle) != OBJ_HANDLE_NIL and pool.slots[handle.id].handle.uint64 == handle.uint64


  proc make*(obj: ObjectType): HandleType =
    var handleId: Int = 0
    if 0 < pool.spareHandles.len:
      result   = H(pool.spareHandles.pop())
      handleId = result.id
    else:

      debug.assert:(pool.count <= OBJ_ID_MAX, "MEM POOL", "All object handles used!")
      handleId = Int(pool.count)
      pool.slots.add(Slot[T,H]())
      result = H(pool.slots[handleId].handle.version * OBJ_BIT_HI + handleId)
    inc pool.count
    pool.slots[handleId].handle = result
    onMakeNotify(result) 


  proc get*(handle: HandleType): var T {.inline.} =
    debug.assert:(handle.alive, "MEM POOL", "Object does not exist")
    pool.slots[handle.id].data
  

  proc `$`*(handle: HandleType): string =
    block:
      var 
        id    {.inject.} = handle.id
        ver   {.inject.} = handle.version
        alive {.inject.} = handle.alive
        name  {.inject.} = $T
      result = &"{name} handle: (id: {id}, version: {ver}, alive: {alive})"


  proc versionReachedCap(api: DebugAPI, handle: HandleType) =
    block:
      var id   {.inject.} = handle.id
      var name {.inject.} = $T
      debug.print(&"[MEM POOL] {name} handle: (id: {id}) reached version cap.")


  proc free(handle: HandleType) =
    dec pool.count
    let handleId    = handle.id
    let deletedSlot = pool.slots[handleId].addr
    var version =  deletedSlot.handle.version
    inc version; if version == OBJ_VER_MAX:
      debug.versionReachedCap(handle)
      version = 0
    deletedSlot.handle = H(version * OBJ_BIT_HI + handleId)
    pool.spareHandles.add(version * OBJ_BIT_HI + handleId)


  proc drop*(handle: HandleType) =
    onDropNotify(handle)
    free(handle)

 
  proc setPoolDefault*(nextPool: Pool[T,H]) =
    pool = nextPool


  template `.`*(self: HandleType, field: untyped): untyped {.dirty.} =
    self.get.field
  
  
  template `.=`*(self: HandleType, field: untyped, value: untyped) =
    self.get.field = value


  proc resetPool*(_:ObjectType) =
    var index = pool.slots.len
    pool.spareHandles.setLen(0) # lazy prevent from adding duplicates
    while 0 < index:
      dec index
      let slot = pool.slots[index].addr
      drop(slot.handle)


  proc Peek*(_:ObjectType, idx: int): var T {.inline.} =
    pool.slots[idx].data
  

  proc PeekHandle*(_:ObjectType, idx: int): var H {.inline.} =
    pool.slots[idx].handle
  

  proc Count*(_:ObjectType): int {.inline.} =
    pool.count


  iterator Handles*(_:ObjectType): H =
    var index = pool.slots.len
    while 0 < index:
      dec index
      let handle = (pool.slots[index].handle)
      if handle.alive:
        yield handle
  {.pop.}


#------------------------------------------------------------------------------------------
# @api mem table
#------------------------------------------------------------------------------------------
import std/tables
import px_engine/pxd/m_key


type MemTable*[T,H] = object
  table: Table[KeyId,H]


proc get*[T,H](map: var MemTable[T,H], tag: string): H =
  var key = toKeyId(tag)
  if not map.table.hasKey(key) or not map.table[key].alive:
    map.table[key] = T.make()
  map.table[key]


proc has*[T,H](map: var MemTable[T,H], tag: string): bool =
  map.table.hasKey(toKeyId(tag))

