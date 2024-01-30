import std/[strutils, strformat, hashes, macros]
import ../[api, m_debug]
export hashes


#------------------------------------------------------------------------------------------
# @api mem pool
#------------------------------------------------------------------------------------------
type
  Handle* = uint64
  Int = uint64
type
  Slot[T, H] = object
    handle*: H
    data*: T
  Pool[T, H] = ref object
    slots*: seq[Slot[T, H]]
    spareHandles*: seq[Int]
    count*: int
const
  HANDLE_NULL* = high(uint64)
  OBJ_BIT_LO: Int = 1 shl 32 - 1
  OBJ_BIT_HI: Int = 1 shl 32
  OBJ_VER_MAX: Int = 1 shl 32 - 1
  OBJ_ID_MAX: int = int(OBJ_BIT_LO)
  OBJ_HANDLE_NIL: Int = high(Int)

 
proc newPool*(api: MemoryAPI, T: typedesc, H: typedesc, presize: static int = 4): Pool[T, H] =
  new(result)
  result.slots = newSeq[Slot[T, H]](presize)
  result.spareHandles = newSeq[Int](0)
  result.count = 1
  result.slots[0].handle = H(OBJ_HANDLE_NIL)
  for i in 1..<presize:
    let slot = result.slots[i].addr
    slot.data = T()
    slot.handle = H(i)
  # for index, slot in result.slots.mpairs:
  #   slot.handle = H(index)
  # var index = result.spareHandles.len
  # while 0 < index:
  #   dec index
  #   result.spareHandles[index] = Int(result.spareHandles.high-index)
  # for slot in result.slots.mitems:
  #   slot.data = T()
  #   slot.handle = H(1)


iterator mitems*[T, H](pool: var Pool[T, H]): var T =
  var index = pool.slots.len
  while 0 < index:
    dec index
    let handle = (pool.slots[index].handle)
    if handle.alive:
      yield pool.slots[index].data


iterator handles*[T, H](pool: var Pool[T, H]): H =
  var index = pool.slots.len
  while 0 < index:
    dec index
    let handle = H(pool.slots[index].handle)
    if handle.alive:
      yield handle


macro genType*(H: untyped) =
  var stmtList = nnkStmtList.newTree()
  var typeSection = nnkTypeSection.newTree(
    nnkTypeDef.newTree(
      nnkPostfix.newTree(
        ident("*"),
        H
    ),
    newEmptyNode(),
    nnkDistinctTy.newTree(
      ident("Handle")
    )
  )
  )
  stmtList.add(typeSection)
  stmtList


template genPoolImpl*(api: MemoryAPI, H: untyped, T: typedesc, genTyped: static bool, defaultSize: static int) =
  {.push checks: off.}
  when not genTyped:
    genType(H)
  var pool = pxd.memory.newPool(T, H, defaultSize)
  type ObjectType = typedesc[T]
  type HandleType = H
  type HandleTypeDesc = typedesc[H]
  type HandleMeta = distinct H

  template onDropNotify(handle: HandleType) =
    when compiles(onDrop(handle)):
      onDrop(handle)


  template onMakeNotify(handle: HandleType) =
    when compiles(onMake(handle)):
      onMake(handle)


  proc `==` (a, b: HandleType): bool {.borrow.}
  proc hash (x: HandleType): Hash {.borrow.}


  proc version*(handle: HandleType): Int {.inline.} =
    Int((Int(handle)-(Int(handle) and OBJ_BIT_LO)) div (OBJ_BIT_HI))


  proc id*(handle: HandleType): Int {.inline.} =
    Int(Int(handle) and OBJ_BIT_LO)


  proc alive*(handle: HandleType): bool {.inline.} =
    int(handle.id) < pool.slots.len and pool.slots[handle.id].handle.uint64 == handle.uint64


  proc make*(obj: HandleTypeDesc): HandleType =
    var slotIndex   = Int(pool.count)
    inc pool.count
    if 0 < pool.spareHandles.len:
      slotIndex = H(pool.spareHandles.pop()).id
    else:
      if slotIndex >= (Int)pool.slots.len:
        pool.slots.add(Slot[T, H](data: T(), handle: H(slotIndex)))
    result = H(pool.slots[slotIndex].handle.version * OBJ_BIT_HI + slotIndex)
    pool.slots[slotIndex].handle = result
    onMakeNotify(result)


  proc `$`*(handle: HandleType): string =
    block:
      var
        id {.inject.} = handle.id
        ver {.inject.} = handle.version
        alive {.inject.} = handle.alive
        name {.inject.} = $T
      result = &"{name} handle: (id: {id}, version: {ver}, alive: {alive})"

  proc get*(handle: HandleType): var T {.inline.} =
    pxd.debug.assert: (handle.alive, "MEM POOL", "Object does not exist ")
    pool.slots[handle.id].data

  proc versionReachedCap(apiDebug: DebugAPI, handle: HandleType) =
    block:
      var id {.inject.} = handle.id
      var name {.inject.} = $T
      pxd.debug.print(&"MEM POOL: {name} handle: (id: {id}) reached version cap.")


  proc free(handle: HandleType) =
    dec pool.count
    let handleId = handle.id
    let deletedSlot = pool.slots[handleId].addr
    var version = deletedSlot.handle.version
    inc version; if version == OBJ_VER_MAX:
      pxd.debug.versionReachedCap(handle)
      version = 0
    deletedSlot.handle = H(version * OBJ_BIT_HI + handleId)
    pool.spareHandles.add(version * OBJ_BIT_HI + handleId)


  proc drop*(handle: HandleType) =
    onDropNotify(handle)
    free(handle)


  proc setPoolDefault*(nextPool: Pool[T, H]) =
    pool = nextPool


  template `.`*(self: HandleType, field: untyped): untyped {.dirty.} =
    self.get.field


  template `.=`*(self: HandleType, field: untyped, value: untyped) =
    self.get.field = value


  proc resetPool*(_: ObjectType) =
    var index = pool.slots.len
    pool.spareHandles.setLen(0) # lazy prevent from adding duplicates
    while 0 < index:
      dec index
      let slot = pool.slots[index].addr
      drop(slot.handle)


  proc Peek*(_: ObjectType, idx: int): var T {.inline.} =
    pool.slots[idx].data


  proc PeekHandle*(_: ObjectType, idx: int): var H {.inline.} =
    pool.slots[idx].handle


  proc Count*(_: ObjectType): int {.inline.} =
    pool.count


  iterator Handles*(_: ObjectType): H =
    var index = pool.slots.len
    while 0 < index:
      dec index
      let handle = (pool.slots[index].handle)
      if handle.alive:
        yield handle
  {.pop.}


template genPool*(api: MemoryAPI, H: untyped, T: typedesc, defaultSize: static int = 4) =
  pxd.memory.genPoolImpl(H, T, false, defaultSize)
template genPoolTyped*(api: MemoryAPI, H: untyped, T: typedesc, defaultSize: static int = 4) =
  pxd.memory.genPoolImpl(H, T, true, defaultSize)
#------------------------------------------------------------------------------------------
# @api mem table
#------------------------------------------------------------------------------------------
import std/tables
import ../m_key


type MemTable*[T, H] = object
  table*: Table[int, H]


proc get*[T, H](map: var MemTable[T, H], tag: string): H = 
  var key = Next(tag).value
  if not map.table.hasKey(key) or not map.table[key].alive:
    map.table[key] = H.make()
  map.table[key]


proc has*[T, H](map: var MemTable[T, H], tag: string): bool =
  map.table.hasKey(Next(tag).value)
