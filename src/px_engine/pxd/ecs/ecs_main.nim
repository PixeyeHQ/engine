import std/hashes
import std/macros
import std/strutils
import std/tables
import ../api
import ../m_memory
import ../m_debug
import ../../px_engine_toolbox
import ecs_d


type PrivateAPI = object
type private = PrivateAPI
type EcsIO = object
  entityInfo*:       SOA_EntityInfo
  nextComponentId*:  int
  regs:              MemTable[RegistryObj,Registry]
  pushedRegs:        seq[Registry]
  componentEnts:     seq[ptr EntsPack]
  cbRegistryAdded:   seq[proc(reg: Registry)]
  cbRegistryReset:   seq[proc(reg: Registry)]
  cbRegistryUsed:    seq[proc(reg: Registry)]
  cbComponentRemove: seq[proc(eid: EcsInt)]


using api: EcsAPI
using private: typedesc[PrivateAPI]


proc initEnts(): EntsPack
proc add*(self: var EntsPack, eid: EcsInt)    {.inline.}
proc delete*(self: var EntsPack, eid: EcsInt) {.inline.}
proc delete(group: EntityGroup, eid: EcsInt)  {.inline.}
proc partof*(eid: EcsInt, group: EntityGroup): bool
proc pushRegistry*(api; reg: Registry)
proc reset*(self: var EntsPack)
proc updateGroups*(eid: EcsInt)

template `[]`(self: var EcsIO, idx: SomeInteger, t: typedesc[Entity]): var Entity =
  self.entityInfo.entity[idx]

template `[]`(self: var EcsIO, idx: SomeInteger, t: typedesc[EntityComps]): var EntityComps =
  self.entityInfo.entityComps[idx]

template `[]`(self: var EcsIO, idx: SomeInteger, t: typedesc[EntityRegistry]): Registry =
  self.entityInfo.entityReg[idx]

template `[]=`(self: var EcsIO, idx: SomeInteger, t: typedesc[EntityRegistry], val: Registry) =
  self.entityInfo.entityReg[idx] = val


pxd.memory.genPoolTyped(Registry, RegistryObj)
pxd.memory.genPoolTyped(EntityGroup, EntityGroupObj)


proc init(io: var EcsIO) =
  io.entityInfo.entity      = newSeq[Entity](ECS_ENTITY_CAP)
  io.entityInfo.entityComps = newSeq[seq[CId]](ECS_ENTITY_CAP)
  io.entityInfo.entityReg   = newSeq[Registry](ECS_ENTITY_CAP)
  io.regs       = MemTable[RegistryObj,Registry]()
  for index in 0..ECS_ENTITY_MAX:
    # handle
    let entity     = io[index, Entity].addr
    entity.id      = u32(index) + 1
    entity.version = u32(1)
    # comps
    let entityComps = io[index, EntityComps].addr
    entityComps[] = newSeqOfCap[CId](4)

var io: EcsIO; init(io)
let debug = pxd.debug

#------------------------------------------------------------------------------------------
# @api ecs handles
#------------------------------------------------------------------------------------------
proc builder*(api): EcsBuilder =
  result


#-----------------------------------------------------------------------------------------
# @api ecs registry
#------------------------------------------------------------------------------------------
proc setEntityRange(reg: Registry; min, max: int) =
  var erange = reg.entityRange.addr
  erange.max  = uint32 (max)
  erange.free = uint32 (max - min)
  erange.min  = uint32  min
  for i in min..<max:
    io[i,EntityRegistry] = reg
  erange.next = EcsInt(min)


proc onMake(reg: Registry) =
  for cb in io.cbRegistryAdded.mitems:
    cb(reg)


proc getRegistry*(api; tag: string): Registry =
  io.regs.get(tag)


proc getRegistry*(api;): Registry =
  var exist = io.regs.has("default")
  result = api.getRegistry("default")
  if not exist:
   # pxd.debug.warn("[ECS] Lazy registry initialization, all entities belong to default registry.")
    result.setEntityRange(0, ECS_ENTITY_MAX)
    pxd.ecs.pushRegistry(result)


proc addRegistry*(api; tag: string, minEntity, maxEntity: int): Registry {.discardable.} =
  result = io.regs.get(tag)
  result.setEntityRange(minEntity,maxEntity)


proc addRegistry*(api; minEntity, maxEntity: int): Registry {.discardable.} =
  var exist = io.regs.has("default")
  result = io.regs.get("default")
  if not exist:
    result.setEntityRange(minEntity,maxEntity)
    pxd.ecs.pushRegistry(result)





#------------------------------------------------------------------------------------------
# @api ecs entity
#------------------------------------------------------------------------------------------
proc id*(self: Ent): u32 {.inline.} = # lo
  u32(EntSizeT(self) and EntLo)


proc version*(self: Ent): u32 {.inline.} = # hi
  u32(u64(EntSizeT(self)-(EntSizeT(self) and EntLo)) div u64(EntHi))


proc registry*(self: Ent|EId): Registry {.inline.} =
  io[self.id, EntityRegistry]


proc registry(index: EcsInt): Registry {.inline.} =
  io[index, EntityRegistry]


proc alive*(self: Ent): bool {.inline.} =
  let entity = io[self.id, Entity].addr
  entity.version == self.version


proc alive*(self: EId): bool {.inline.} =
  true


proc entity*(api; reg: Registry): Ent {.inline.} =
  ## Register new entity.
  # This is a dynamic list of alive and destroyed entities.
  pxd.debug.assert:(reg.entityRange.free>0, "ECS", "No free indices available")
  let erange = reg.entityRange.addr
  dec erange.free
  let id      = erange.next
  let einfo   = io[id, Entity].addr
  erange.next = einfo.id
  result = Ent(einfo.version * EntHi + EntSizeT(id))


proc entity*(api; reg: Registry, tag: string): Ent {.inline.} =
  result = api.entity(reg)
  reg.entityTagged[tag] = result


proc getEntity*(api; reg: Registry, tag: string): Ent {.inline.} =
  reg.entityTagged[tag]


proc `$`*(self: Ent): string =
  result = &"entity: (id: {self.id.u32}, ver: {self.version}, reg: {self.registry.id}, alive: {self.alive})"


proc `$`*(self: EId): string =
  result = &"entity: (id: {self.id.u32}, reg: {self.registry.id})"


proc recycle(private; eid: EcsInt) {.inline.} =
  let reg     = eid.registry()
  let einfo   = io[eid, Entity].addr
  var version = einfo.version
  einfo.id    = reg.entityRange.next
  reg.entityRange.next = eid
  inc reg.entityRange.free
  inc version
  if version == ECS_ENTITY_VERSION_MAX:
    version = 1
  einfo.version = version


proc dropGroups(private; eid: EcsInt) {.inline.} =
  let reg = eid.registry.get.addr
  for cid in io[eid, EntityComps].mitems:
    io.cbComponentRemove[cid](eid)
    for group in reg.cgroups[cid].mitems:
      if eid.partof(group):
        group.delete(eid)


proc drop*(api; self: Ent|EId) =
  pxd.debug.assert:(self.alive, "ECS", "Entity is already destroyed.")
  private.dropGroups(self.id)
  private.recycle(self.id)
  io[self.id, EntityComps].setLen(0)


template check(entity: Ent, ctype: typedesc): bool =
  hasComponent(entity.id, ctype)


proc has*(entity: Ent, T: typedesc): bool =
  check(entity, T)


proc has*(entity: Ent, T, Y: typedesc): bool =
  check(entity, T) and
  check(entity, Y)


proc reset*(api; reg: Registry) =
  let erange = reg.entityRange.addr
  let max = int erange.max - 1
  let min = int erange.min
  for eid in countdown(max,min):
    private.recycle(eid.EcsInt)
    io[eid,EntityComps].setLen(0)
  for group in reg.entityGroups.items:
    group.get.ents.reset()
  for cb in io.cbRegistryReset.mitems:
    cb(reg)
  reg.entityTagged.clear()


proc pushRegistry*(api; reg: Registry) =
  io.pushedRegs.add(reg)
  for cb in io.cbRegistryUsed.mitems:
    cb(reg)


proc pushRegistry*(api; tag: string) =
  let reg = io.regs.get(tag)
  io.pushedRegs.add(reg)
  for cb in io.cbRegistryUsed.mitems:
    cb(reg)


proc popRegistry*(api;) =
  discard io.pushedRegs.pop()
  let reg = io.pushedRegs[io.pushedRegs.high]
  for cb in io.cbRegistryUsed.mitems:
    cb(reg)


#------------------------------------------------------------------------------------------
# @api ecs ents
#------------------------------------------------------------------------------------------
proc initEnts(): EntsPack =
  result.sparse = newSeq[EcsInt](ECS_ENTITY_CAP)
  result.packed = newSeqOfCap[EId](ECS_ENTITY_CAP) 
  for i in 0..result.sparse.high:
    result.sparse[i] = Ent.Nil
  

proc high*(self: var EntsPack): int {.inline.} =
  (self.count-1)


proc add*(self: var EntsPack, eid: EcsInt) =
  let indexNext = self.count; inc self.count
  self.sparse[eid] = u32 indexNext
  if indexNext < self.packed.len:
    self.packed[indexNext] = EId eid
  else:
    self.packed.add(EId eid)
  self.changed = true


proc getAdd*(self: var EntsPack, eid: EcsInt): int =
  result = self.count; inc self.count
  self.sparse[eid] = u32 result
  if result < self.packed.len:
    self.packed[result] = EId eid
  else:
    self.packed.add(EId eid)
  self.changed = true


proc delete*(self: var EntsPack, eid: EcsInt) {.inline.} =
  var sparse  = self.sparse.addr
  var packed  = self.packed.addr
  let deleted = sparse[eid]
  let last    = sparse[u32(packed[self.high])]
  swap(packed[deleted],packed[last])
  swap(sparse[u32(packed[deleted])], sparse[u32(packed[last])])
  sparse[eid] = Ent.Nil
  dec self.count
  self.changed = true


proc delete*(self: var EntsPack, eid: EcsInt, deleted: var u32, last: var u32) {.inline.}  =
  let sparse = self.sparse.addr
  let packed = self.packed.addr
  deleted = sparse[eid]
  last    = sparse[u32(packed[self.high])]
  swap(packed[deleted], packed[last])
  swap(sparse[u32(packed[deleted])], sparse[u32(packed[last])])
  sparse[eid] = Ent.Nil
  dec self.count
  self.changed = true
  

proc has*(self: var EntsPack, entityId: SomeNumber): bool {.inline.} =
  self.sparse[entityId] < Ent.Nil


proc has*(self: var EntsPack, entity: Ent): bool {.inline.} =
  self.sparse[entity.id] < Ent.Nil


proc reset*(self: var EntsPack) =
  for i in 0..self.sparse.high:
    self.sparse[i] = Ent.Nil
  self.packed.setLen(0)
  self.count  = 0


proc siftDown(data: var seq[EId], startIdx, endIdx: int, cmp: EntityComparer) =
  var rootIdx = startIdx
  while true:
    let leftChildIdx = 2 * rootIdx + 1
    if leftChildIdx >= endIdx:
      break
    let rightChildIdx = leftChildIdx + 1
    let swapIdx =
      if rightChildIdx >= endIdx or cmp(data[leftChildIdx], data[rightChildIdx]) > 0:
        leftChildIdx
      else:
        rightChildIdx
    if cmp(data[swapIdx], data[rootIdx]) > 0:
      swap(data[rootIdx], data[swapIdx])
      rootIdx = swapIdx
    else:
      break


proc sort*(data: var seq[EId], length: int, cmp: EntityComparer) =
  # Build binary heap
  for i in 1..<length:
    var childIdx = i
    while childIdx > 0:
      let parentIdx = (childIdx - 1) div 2
      if cmp(data[childIdx], data[parentIdx]) > 0:
        swap(data[childIdx], data[parentIdx])
        childIdx = parentIdx
      else:
        break
  # Perform heap sort
  var endIdx = length - 1
  while endIdx > 0:
    swap(data[0],data[endIdx])
    siftDown(data,0,endIdx,cmp)
    dec endIdx


proc trySort*(data: var EntsPack, cmp: EntityComparer) =
  if data.changed:
    sort(data.packed, data.count, cmp)


#------------------------------------------------------------------------------------------
# @api ecs entity groups
#------------------------------------------------------------------------------------------
proc updateEntities(api;) =
  for reg in io.regs.table.values:
    let min = reg.entityRange.min
    let max = reg.entityRange.max
    for index in min..max:
      updateGroups(index)


proc findGroup(reg: Registry, cmask: ComponentMask): EntityGroup =
  let mreg = reg.get.addr
  let h_all_incl = cmask.maskall.incl.hash
  let h_all_excl = cmask.maskall.excl.hash
  let h_any_incl = cmask.maskany.incl.hash
  let h_any_excl = cmask.maskany.excl.hash
  for group in mreg.entityGroups.items:
    let mgroup = group.get.addr
    if mgroup.cmask.maskall.incl.hash == h_all_incl and
       mgroup.cmask.maskall.excl.hash == h_all_excl and
       mgroup.cmask.maskany.incl.hash == h_any_incl and
       mgroup.cmask.maskany.excl.hash == h_any_excl: 
         return group
  result = EntityGroup.Nil


proc getGroup(reg: Registry, cmask: ComponentMask): EntityGroup =
  let mreg = reg.get.addr
  result = findGroup(reg, cmask)
  if result == EntityGroup.Nil:
    result  = mreg.entityGroups.append(make(EntityGroup))
    result.get.cmask = cmask
    result.get.ents  = initEnts()
    for cid in cmask.maskAll.incl:
      reg.cgroups.grow(cid.int):
        reg.cgroups[cid].add(result)
    for cid in cmask.maskAll.excl:
       reg.cgroups.grow(cid.int):
        reg.cgroups[cid].add(result)
    for cid in cmask.maskAny.incl:
     reg.cgroups.grow(cid.int):
        reg.cgroups[cid].add(result)
    for cid in cmask.maskAny.excl:
      reg.cgroups.grow(cid.int):
        reg.cgroups[cid].add(result)
    pxd.ecs.updateEntities()


proc add(group: EntityGroup, eid: EcsInt) {.inline.} =
  group.get.ents.add(eid)
  group.changed = true


proc delete(group: EntityGroup, eid: EcsInt) {.inline.} =
  group.get.ents.delete(eid)
  group.changed = true


proc partof*(eid: EcsInt, group: EntityGroup): bool =
  group.get.ents.sparse[eid] < Ent.Nil


proc checkMask(eid: EcsInt, group: EntityGroup, grouped: var bool, matched: var bool) {.inline.} =
  var amountExcl = 0
  var mgroup     = group.get.addr
  ##########
  # partof
  ##########
  grouped = mgroup.ents.sparse[eid] < Ent.Nil
  ##########
  # matchAll
  ##########
  matched = true
  for cid in mgroup.cmask.maskAll.incl:
    if  Ent.Nil == io.componentEnts[cid].sparse[eid]:
      matched = false
      return
  for cid in mgroup.cmask.maskAll.excl:
    if io.componentEnts[cid].sparse[eid] < Ent.Nil:
      inc amountExcl
  matched = amountExcl == 0 or amountExcl < mgroup.cmask.maskAll.excl.len
  if not matched: return
  ##########
  # matchAny
  ##########
  for cid in mgroup.cmask.maskAny.incl:
    matched = false
    if io.componentEnts[cid].sparse[eid] < Ent.Nil:
      matched = true
      break
  if matched == false: return
  for cid in mgroup.cmask.maskAny.excl:
    if io.componentEnts[cid].sparse[eid] < Ent.Nil:
      matched = false
      return


template impl_updateGroups() {.dirty.} =
  for group in reg.cgroups[cid].mitems:
    checkMask(eid, group, grouped, matched)
    if not grouped and matched:
      group.add(eid)
    elif grouped and not matched:
      group.delete(eid)


proc updateGroups*(eid: EcsInt) =
  var grouped: bool
  var matched: bool
  let reg = eid.registry
  for cid in io[eid, EntityComps].mitems:
    impl_updateGroups()


proc updateGroups*(eid: EcsInt, cid: int) {.inline.} =
  var grouped: bool
  var matched: bool
  let reg = eid.registry
  impl_updateGroups()


proc tryGroupSort*(data: var EntityGroup, cmp: EntityComparer) =
  if data.changed:
    sort(data.ents.packed, data.ents.count, cmp)
    data.changed = false


# DEFAULT
iterator components*[C1](api; c1: typedesc[C1]): ptr C1 =
  let st  = C1.Storage()
  var index = st.ents.count
  while 0 < index:
    dec index
    yield st.comps[index].addr

iterator components*[C1](api; e: typedesc[Ent], c1: typedesc[C1]): tuple[eid: EId, c1: ptr C1] =
  let st  = C1.Storage()
  var index = st.ents.count
  while 0 < index:
    dec index
    yield (st.ents.packed[index], st.comps[index].addr)

iterator components*[C1,C2](api; c1: typedesc[C1], c2: typedesc[C2]): tuple[c1: ptr C1, c2: ptr C2] =
  let st1  = C1.Storage()
  let st2  = C2.Storage()
  var index = 0
  if st2.ents.count < st1.ents.count:
    index = st2.ents.count
    while 0 < index:
      dec index
      yield (C1.Component(st2.ents.packed[index]), st2.comps[index].addr)
  else:
    index = st1.ents.count
    while 0 < index:
     dec index
     yield (st1.comps[index].addr, C2.Component(st1.ents.packed[index]))

iterator components*[C1,C2](api; e: typedesc[Ent], c1: typedesc[C1], c2: typedesc[C2]): tuple[eid: EId, c1: ptr C1, c2: ptr C2] =
  let st1  = C1.Storage()
  let st2  = C2.Storage()
  var index = 0
  if st2.ents.count < st1.ents.count:
    index = st2.ents.count
    while 0 < index:
      dec index
      let eid = st2.ents.packed[index]
      yield (eid, C1.Component(eid), st2.comps[index].addr)
  else:
    index = st1.ents.count
    while 0 < index:
     dec index
     let eid = st1.ents.packed[index]
     yield (eid, st1.comps[index].addr, C2.Component(eid))


# INVERSED
iterator componentsInversed*[C1](api; c1: typedesc[C1]): ptr C1 =
  let st  = C1.Storage()
  var index = 0
  while index < st.ents.count:
    yield st.comps[index].addr
    inc index

iterator componentsInversed*[C1](api; e: typedesc[Ent], c1: typedesc[C1]): tuple[eid: EId, c1: ptr C1] =
  let st  = C1.Storage()
  var index = 0
  while index < st.ents.count:
    yield (st.ents.packed[index], st.comps[index].addr)
    inc index

iterator componentsInversed*[C1,C2](api; c1: typedesc[C1], c2: typedesc[C2]): tuple[c1: ptr C1, c2: ptr C2] =
  let st1  = C1.Storage()
  let st2  = C2.Storage()
  var index = 0
  if st2.ents.count < st1.ents.count:
    index = 0
    while index < st2.ents.count:
      yield (C1.Component(st2.ents.packed[index]), st2.comps[index].addr)
      inc index
  else:
    index = 0
    while index < st1.ents.count:
     yield (st1.comps[index].addr, C2.Component(st1.ents.packed[index]))
     inc index

iterator componentsInversed*[C1,C2](api; e: typedesc[Ent], c1: typedesc[C1], c2: typedesc[C2]): tuple[eid: EId, c1: ptr C1, c2: ptr C2] =
  let st1  = C1.Storage()
  let st2  = C2.Storage()
  var index = 0
  if st2.ents.count < st1.ents.count:
    index = 0
    while index < st2.ents.count:
      let eid = st2.ents.packed[index]
      yield (eid, C1.Component(eid), st2.comps[index].addr)
      inc index
  else:
    index = 0
    while index < st1.ents.count:
     let eid = st1.ents.packed[index]
     yield (eid, st1.comps[index].addr, C2.Component(eid))
     inc index


#------------------------------------------------------------------------------------------
# @api ecs entity builder
#------------------------------------------------------------------------------------------
proc entity*(api: EcsBuilder, reg: Registry): var EntityBuilder =
  var builder {.global.} : EntityBuilder = EntityBuilder()
  builder.reg = reg
  builder.ent = pxd.ecs.entity(reg)
  builder


proc entity*(api: EcsBuilder, reg: Registry, tag: string): var EntityBuilder =
  var builder {.global.} : EntityBuilder = EntityBuilder()
  builder.reg = reg
  builder.ent = pxd.ecs.entity(reg, tag)
  builder


proc build*(builder: var EntityBuilder): Ent {.discardable.} =
  result = builder.ent
  updateGroups(result.id)


#------------------------------------------------------------------------------------------
# @api ecs component
#------------------------------------------------------------------------------------------
proc format_component_alias(s: string): string {.used.} =
    ## Makes distinct shortcut type alias for component types.
    ## Example: ComponentCamera -> CCamera
    result = s
    if not result.contains("Component") and not result.contains("Tag"): return result
    var letters: array[8, int]
    var index = 0
    var nletter = 0
    while index < result.len:
        if result[index] in 'A'..'Z':
            letters[nletter] = index
            inc nletter
            assert nletter < 7, "too long name"
        inc index
    if nletter >= 2:
        delete(result, 1..letters[1]-1)
        return toUpperAscii(result[0]) & substr(result, 1)
    return s


proc format_component_alias_clike(s: string): string {.used.} =
  result = format_component_alias(s)
  result = toLower(result)
  result = result & "_t"


proc format_component_api(s: string): string =
  result = format_component_alias(s)
  result = toLower(result)


macro gen_api_component(ctype: typedesc, cmode: static int) {.used.} =
  ## Makes api for getting component without any checks using component type shortcut.
  ## Example: let ctransform = entity.ctransform
  let tname = strval(ctype)
  let pname = format_component_api(tname)
  var source: string
  if cmode == AS_COMPONENT:
    source = &("""
let {pname}_id* = int {tname}.Id
when {tname} is ref:
  proc {pname}*(entity: Ent|EId): {tname} {{.inline.}} =
    result = component(entity, {tname})
  proc {pname}*(node: EntityObj): {tname} {{.inline.}} =
    result = component(node.entity, {tname})
else:
  proc {pname}*(entity: Ent|EId): ptr {tname} {{.inline.}} =
    result = component(entity, {tname})
  proc {pname}*(node: EntityObj): ptr {tname} {{.inline.}} =
    result = component(node.entity, {tname})""")
  else:
    source = &("""
let {pname}_id* = int {tname}.Id
proc {pname}*(entity: Ent|EId): var int {{.inline.}} =
  component(entity, {tname})[].int
proc {pname}*(node: EntityObj): var int {{.inline.}} =
  component(node.entity, {tname})[].int""")
  result = parsestmt(source)


template GEN_ECS_COMPONENT_API(T: typedesc, cmode: int, initSize: int) =
  #------------------------------------------------------------------------------------------
  # @api component define
  #------------------------------------------------------------------------------------------
  type ctype          = typedesc[T]
  type CPtr  {.used.} = ptr T
  type CStorage       = object
    comps*: seq[T]
    ents*:  EntsPack
    active: bool

  proc growStorage(reg: Registry, _: ctype)
  proc setStorage(reg: Registry, _: ctype)
  proc deleteComponentEnd*(eid: EcsInt, _: ctype) {.inline.}

  let ctypeId: int = io.nextComponentId; inc io.nextComponentId
  var storages = newSeq[CStorage]()#initObjectContext(CStorage,0)
  var storage: ptr CStorage

  
  for reg in RegistryObj.Handles:
    growStorage(reg, ctype)
  
  growStorage(pxd.ecs.getRegistry(), ctype)
  setStorage(pxd.ecs.getRegistry(), ctype)

  io.cbRegistryAdded.add(proc(reg: Registry) = growStorage(reg, ctype))
  io.cbRegistryReset.add(proc(reg: Registry) = storages[reg.id].ents.reset())
  io.cbRegistryUsed.add(proc(reg: Registry)  = setStorage(reg, ctype))
  
  io.cbComponentRemove.grow(ctypeId):
    io.cbComponentRemove[ctypeId] =  proc(eid: EcsInt) = deleteComponentEnd(eid, ctype)


  #------------------------------------------------------------------------------------------
  # @api component storage
  #------------------------------------------------------------------------------------------
  template Id*(_: ctype): CId =
    CId(ctypeId)
  

  proc Storage*(_: ctype): ptr CStorage =
    storage

  when T is ref:
    template Component*(_: ctype, entity: Ent|EId): T =
      storage.comps[storage.ents.sparse[entity.id]]


    template component(eid: EcsInt, _: ctype): T =
      storage.comps[storage.ents.sparse[eid]]


    template component(entity: Ent|EId, _: ctype): T =
      storage.comps[storage.ents.sparse[entity.id]]

  else:
    template Component*(_: ctype, entity: Ent|EId): CPtr =
      storage.comps[storage.ents.sparse[entity.id]].addr


    template component(eid: EcsInt, _: ctype): CPtr =
      storage.comps[storage.ents.sparse[eid]].addr


    template component(entity: Ent|EId, _: ctype): CPtr =
      storage.comps[storage.ents.sparse[entity.id]].addr


  proc hasComponent*(eid: EcsInt, _: ctype): bool {.inline, discardable.} =
    storage.ents.sparse[eid] < Ent.Nil #self.ents.count


  proc growStorage(reg: Registry, _: ctype) =
    storages.grow(reg.id.int)
    var storage = storages[reg.id.int].addr
    if storage.active:
      return
    storage.ents = initEnts()
    storage.comps = newSeq[T](initSize)
    storage.active = true
    io.componentEnts.grow(ctypeId)
    reg.cgroups.grow(ctypeId)


  proc setStorage(reg: Registry, _: ctype) =
    storage = storages[reg.id.int].addr
    io.componentEnts[ctypeId] = storage.ents.addr

  
  gen_api_component(T, cmode)
  
  
  #------------------------------------------------------------------------------------------
  # @api component
  #------------------------------------------------------------------------------------------
  when T is ref:
    proc addComponent(eid: EcsInt, _: ctype, item: T): int {.inline.} =
      let cid = storage.ents.getAdd(eid)
      io[eid, EntityComps].add(T.Id)
      storage.comps.grow(cid)
      storage.comps[cid] = item
      cid
  #else:
  proc addComponent(eid: EcsInt, _: ctype): int {.inline.} =
    let cid = storage.ents.getAdd(eid)
    io[eid, EntityComps].add(T.Id)
    storage.comps.grow(cid)
    cid


  proc deleteComponentEnd*(eid: EcsInt, _: ctype) {.inline.} =
    var deleted = 0.u32
    var last    = 0.u32
    storage.ents.delete(eid, deleted, last)
    when compiles(storage.comps[deleted].onRemove()):
      storage.comps[deleted].onRemove()
    swap(storage.comps[deleted], storage.comps[last])


  proc deleteComponentBegin*(eid: EcsInt, _: ctype) {.inline.} =
    # [?] Faster alternative: resize entitycomps to biggest ComponentId to delet
    let indexToRemove = io[eid, EntityComps].find(T.Id) 
    io[eid, EntityComps].del(indexToRemove)
    deleteComponentEnd(eid, ctype)
    updateGroups(eid, ctypeId)


  #------------------------------------------------------------------------------------------
  # @api component & segment public
  #------------------------------------------------------------------------------------------
  when cmode == AS_COMPONENT:
    when T is ref:
      proc get*(self: Ent|EId, _: ctype): T {.discardable, inline.} =
        if hasComponent(self.id, ctype): 
          return component(self.id, ctype)
        result = storage.comps[addComponent(self.id, ctype)]
        updateGroups(self.id, ctypeId)


      proc get*(self: EntityObj, ctypeof: ctype): T {.discardable, inline.} =
        self.entity.get(ctypeof)


      template get*(self: EntityObj, ctypeof: ctype, code: untyped) =
        block:
          var c {.inject.} = self.entity.get(ctypeof)
          code


      proc add*(builder: var EntityBuilder, _: ctype): T {.discardable,inline.} =
        result = storage.comps[addComponent(builder.ent.id, ctype)]

      # [?] Might be not good idea to use 'put' name since it's used for tags already.
      proc put*(self: Ent|EId, _: ctype, item: T) =
        if hasComponent(self.id, ctype): 
          var comp = component(self.id, ctype)
          comp = item
        else:
          discard addComponent(self.id, ctype, item)
          updateGroups(self.id, ctypeId)


      proc put*(self: EntityObj, ctypeof: ctype, item: T) =
        self.entity.put(ctypeof, item)
    else:
      proc get*(self: Ent|EId, _: ctype): CPtr {.discardable, inline.} =
        if hasComponent(self.id, ctype): 
          return component(self.id, ctype)
        result = storage.comps[addComponent(self.id, ctype)].addr
        updateGroups(self.id, ctypeId)
      

      proc get*(self: EntityObj, ctypeof: ctype): CPtr {.discardable, inline.} =
        self.entity.get(ctypeof)


      template get*(self: EntityObj, ctypeof: ctype, code: untyped) =
        block:
          var c {.inject.} = self.entity.get(ctypeof)
          code


      proc add*(builder: var EntityBuilder, _: ctype): CPtr {.discardable,inline.} =
        result = storage.comps[addComponent(builder.ent.id, ctype)].addr


    proc remove*(self: Ent|EId, _: ctype) {.inline.} =
      deleteComponentBegin(self.id, ctype)
    

    proc remove*(self: EntityObj, ctypeof: ctype) {.inline.} =
      self.entity.remove(ctypeof)


  when cmode == AS_TAG:
    proc `+` *(a, b: T): T {.borrow.}
    proc `-` *(a, b: T): T {.borrow.}


    proc put*(self: Ent|EId, _: ctype, amount: int = 1) {.inline.} =
      if not hasComponent(self.id, ctype):
        discard addComponent(self.id, ctype)
      let slot = component(self.id, ctype)
      slot[] = amount.T
      updateGroups(self.id, ctypeId)


    proc put*(self: EntityObj, ctypeof: ctype, amount: int = 1) {.inline.} =
      self.entity.put(ctype,amount)


    proc add*(builder: var EntityBuilder, _: ctype, amount: int) =
      builder.ent.put(ctype,amount)


    proc inc*(self: Ent|EId, _: ctype){.inline.} =
      if not hasComponent(self.id, ctype):
        discard addComponent(self.id, ctype)
      let slot = component(self.id, ctype)
      slot[].int += 1
      updateGroups(self.id, ctypeId)


    proc inc*(self: EntityObj, ctypeof: ctype){.inline.} =
      self.entity.inc(ctypeof)


    proc inc*(self: Ent|EId, _: ctype, amount: int) =
      # todo: assert, amount can't be smaller than 1
      if not hasComponent(self.id, ctype):
        discard addComponent(self.id, ctype)
      var slot = component(self.id, ctype)
      slot[].int += amount
      updateGroups(self.id, ctypeId)


    proc inc*(self: EntityObj, ctypeof: ctype, amount: int){.inline.} =
      self.entity.inc(ctypeof, amount)

   
    proc remove*(self: Ent|EId, _: ctype) {.inline.} =
      deleteComponentBegin(self.id, ctype)


    proc remove*(self: EntityObj, ctypeof: ctype){.inline.} =
      self.entity.remove(ctypeof)


    proc dec*(self: Ent|EId, _: ctype){.inline.} =
      let slot = component(self.id, ctype)
      slot[].int -= 1
      if slot[].int <= 0:
        remove(self, ctype)
      updateGroups(self.id, ctypeId)


    proc dec*(self: Ent|EId, _: ctype, amount: int) =
      let slot = component(self.id, ctype)
      slot[].int -= amount
      if slot[].int <= 0:
        remove(self, ctype)
      updateGroups(self.id, ctypeId)


    proc dec*(self: EntityObj, ctypeof: ctype, amount: int){.inline.} =
      self.entity.dec(ctypeof, amount)


    proc dec*(self: EntityObj, ctypeof: ctype){.inline.} =
      self.entity.dec(ctypeof)


macro gen_component_macro(ctype: typed, initSize: static int = 0): untyped =
  proc getCMode(cname: var string): int =
    if cname.contains("Tag"):
        return AS_TAG
    else:
        return AS_COMPONENT
  proc addAlias(statements: NimNode, cname: string, cmd: proc(s:string): string) =
        var calias = cmd(cname)
        if calias == cname: return
        let tree =
            nnkTypeSection.newTree(
                nnkTypeDef.newTree(
                nnkPostfix.newTree(
                    newIdentNode("*"),
                    newIdentNode(calias)),
                    newEmptyNode(),
                    nnkBracketExpr.newTree(
                      newIdentNode("typedesc"),
                      newIdentNode(cname)
                    )))
        statements.add(tree)
  var cname = $ctype
  var cmode = getCMode(cname)
  let tree  = nnkCommand.newTree()

  tree.insert(0, bindsym("GEN_ECS_COMPONENT_API", brForceOpen))
  tree.insert(1, newIdentNode(cname))
  tree.insert(2, newIntLitNode(cmode))
  tree.insert(3, newIntLitNode(initSize))

  let statements = nnkStmtList.newTree(tree)
  statements.addAlias(cname, format_component_alias)
  statements.addAlias(cname, format_component_alias_clike)
  return statements


template genComponent*(api: EcsAPI; ctype: typed, initSize: static int = 1): untyped =
  gen_component_macro(ctype, initSize)


template component*(api: GenerateAPI, ctype: typed, initSize: static int = 1): untyped =
  gen_component_macro(ctype, initSize)


#------------------------------------------------------------------------------------------
# @api ecs system
#------------------------------------------------------------------------------------------
macro gen_system_component_mask(vname: untyped, ctypes: varargs[untyped]): untyped =
  let kernel = nnkObjConstr.newTree()
  let nodeMaskInclude = nnkBracket.newTree()
  let nodeMaskExclude = nnkBracket.newTree()
  
  for ctype in ctypes.items:
    var component: string
    var nextMaskNode: NimNode
    if ctype.len > 0 and $ctype[0] == "!":
        component = $ctype[1]
        nextMaskNode = nodeMaskExclude
    else:
        component = $ctype
        nextMaskNode = nodeMaskInclude
    nextMaskNode.add(nnkCall.newTree(newDotExpr(ident(component), ident("Id"))))
  let treeMaskInclude = 
    nnkExprColonExpr.newTree(
      ident("incl"),
        nnkPrefix.newTree().add(ident("@")).add(nodeMaskInclude))
  let treeMaskExclude =
    nnkExprColonExpr.newTree(
      ident("excl"),
        nnkPrefix.newTree().add(ident("@")).add(nodeMaskExclude))

  kernel.add(ident("ComponentMaskPart"))
  kernel.add(treeMaskInclude)
  kernel.add(treeMaskExclude)
  result = kernel


proc count*(system: var EntityQuery): int =
    system.group.get.ents.count.int


iterator sorted*(system: var EntityQuery, cmp: EntityComparer): EId {.inline.} =
  var pack {.global.}: seq[EId]
  let group = system.group.get.addr
  var index = group.ents.count
  pack = group.ents.packed
  mergeSort(pack, index, cmp)
  while 0 < index:
    dec index
    yield pack[index]


iterator entities*(system: var EntityQuery): EId {.inline.} =
  let group = system.group.get.addr
  var index = group.ents.count
  while 0 < index:
    dec index
    yield group.ents.packed[index]


iterator entitiesInversed*(system: var EntityQuery): EId {.inline.} =
  let group = system.group.get.addr
  var index = 0
  while index < group.ents.count:
    yield group.ents.packed[index]
    inc index


template onChanged*(system: var EntityQuery, code: untyped): untyped =
  if system.group.changed:
    code

#------------------------------------------------------------------------------------------
# @api ecs system builder
#------------------------------------------------------------------------------------------
proc update*(api;) =
  var flag {.global.} = false
  if not flag : api.updateEntities(); flag = true
  for reg in io.regs.table.values:
    for group in reg.entityGroups.items:
      group.changed = false


#------------------------------------------------------------------------------------------
# @api entity query
#------------------------------------------------------------------------------------------
template setGroup*(self: var EntityQuery, code: untyped) =
  block:
    template with(ctypes: varargs[untyped]) {.used.} =
      self.mask.maskAll = gen_system_component_mask(maskAll, ctypes)
    template withAny(ctypes: varargs[untyped]) {.used.} =
      self.mask.maskAny = gen_system_component_mask(maskAny, ctypes)
    code
    self.group = getGroup(self.reg, self.mask)


template query*(api: EcsAPI, registry: Registry, code: untyped): EntityQuery =
  var self = EntityQuery(reg: registry)
  block:
    template with(ctypes: varargs[untyped]) {.used.} =
      self.mask.maskAll = gen_system_component_mask(maskAll, ctypes)
    template withAny(ctypes: varargs[untyped]) {.used.} =
      self.mask.maskAny = gen_system_component_mask(maskAny, ctypes)
    code
    self.group = getGroup(self.reg, self.mask)
  self


#------------------------------------------------------------------------------------------
# @api methods
#------------------------------------------------------------------------------------------
method drop*(self: EntityObj) = pxd.ecs.drop(self.entity)
method init*(self: EntityObj) {.base.} = discard
method init*(self: EntityObj, params: RootObj) {.base.} = discard
proc init*(self: EntityObj, reg: Registry) = self.entity = pxd.ecs.entity(reg)