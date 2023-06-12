import std/hashes
import std/macros
import std/strutils
import std/tables
import engine/pxd/api as pxd_api except ents
import engine/pxd/data/m_mem_pool
import engine/pxd/data/m_obj_context
import engine/pxd/m_utils_collections
import engine/pxd/m_key
import engine/pxd/m_debug
import ecs_d


type PrivateAPI = object
type private = PrivateAPI
type EcsIO = object
  entityInfo*:       SOA_EntityInfo
  nextComponentId*:  int
  regs:              MemTable[RegistryObj,Registry]
  sys:               MemTable[SystemObj,System]
  pushedRegs:        seq[Registry]
  componentEnts:     seq[ptr EntsPack]
  cbRegistryAdded:   seq[proc(reg: Registry)]
  cbRegistryReset:   seq[proc(reg: Registry)]
  cbRegistryUsed:    seq[proc(reg: Registry)]
  cbComponentRemove: seq[proc(eid: EcsInt)]


using api: EcsAPI
using private: typedesc[PrivateAPI]


proc initEnts(): EntsPack
proc add*(self: var EntsPack, eid: EcsInt) {.inline.}
proc delete*(self: var EntsPack, eid: EcsInt) {.inline.}
proc delete(group: EntityGroup, eid: EcsInt) {.inline.}
proc partof*(eid: EcsInt, group: EntityGroup): bool
proc pushRegistry*(api; reg: Registry)
proc reset*(self: var EntsPack)


template `[]`(self: var EcsIO, idx: SomeInteger, t: typedesc[Entity]): var Entity =
  self.entityInfo.entity[idx]

template `[]`(self: var EcsIO, idx: SomeInteger, t: typedesc[EntityComps]): var EntityComps =
  self.entityInfo.entityComps[idx]

template `[]`(self: var EcsIO, idx: SomeInteger, t: typedesc[EntityRegistry]): Registry =
  self.entityInfo.entityReg[idx]

template `[]=`(self: var EcsIO, idx: SomeInteger, t: typedesc[EntityRegistry], val: Registry) =
  self.entityInfo.entityReg[idx] = val



GEN_MEM_POOL(RegistryObj,    Registry)
GEN_MEM_POOL(EntityGroupObj, EntityGroup)
GEN_MEM_POOL(SystemObj,      System)


proc init(io: var EcsIO) =
  io.entityInfo.entity      = newSeq[Entity](ECS_ENTITY_CAP)
  io.entityInfo.entityComps = newSeq[seq[CId]](ECS_ENTITY_CAP)
  io.entityInfo.entityReg   = newSeq[Registry](ECS_ENTITY_CAP)
  io.regs       = MemTable[RegistryObj,Registry]()
  for index in 0..ECS_ENTITY_MAX:
    # handle
    let entity     = io[index, Entity].addr
    entity.id      = u32(index) + 1
    entity.version = u32(0)
    # comps
    let entityComps = io[index, EntityComps].addr
    entityComps[] = newSeqOfCap[CId](4)

var io: EcsIO; init(io)


#------------------------------------------------------------------------------------------
# @api ecs handles
#------------------------------------------------------------------------------------------
proc builder*(api): EcsBuilder =
  result

# proc `@:`*(self: Registry):  RegistryBuilder =
#   result = self.RegistryBuilder


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
    debug.warn("[ECS] Lazy registry initialization, all entities belong to default registry.")
    result.setEntityRange(0,ECS_ENTITY_MAX)
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
  u32(int(EntSizeT(self)-(EntSizeT(self) and EntLo)) / int(EntHi))


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
  debug.assert:(reg.entityRange.free>0, "ECS", "No free indices available")
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
    version = 0
  einfo.version = version


proc dropGroups(private; eid: EcsInt) {.inline.} =
  let reg = eid.registry.get.addr
  for cid in io[eid, EntityComps].mitems:
    io.cbComponentRemove[cid](eid)
    for group in reg.cgroups[cid].mitems:
      if eid.partof(group):
        group.delete(eid)


proc drop*(api; self: Ent|EId) =
  debug.assert:(self.alive, "ECS", "Entity is already destroyed.")
  private.dropGroups(self.id)
  private.recycle(self.id)


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


proc getSystem*(api; reg: Registry, tag: string): System =
  io.sys.get(tag & $reg.id)


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


proc getAdd*(self: var EntsPack, eid: EcsInt): int =
  result = self.count; inc self.count
  self.sparse[eid] = u32 result
  if result < self.packed.len:
    self.packed[result] = EId eid
  else:
    self.packed.add(EId eid)


proc delete*(self: var EntsPack, eid: EcsInt) {.inline.} =
  var sparse  = self.sparse.addr
  var packed  = self.packed.addr
  let deleted = sparse[eid]
  let last    = sparse[u32(packed[self.high])]
  swap(packed[deleted],packed[last])
  swap(sparse[u32(packed[deleted])], sparse[u32(packed[last])])
  sparse[eid] = Ent.Nil
  dec self.count


proc delete*(self: var EntsPack, eid: EcsInt, deleted: var u32, last: var u32) {.inline.}  =
  let sparse = self.sparse.addr
  let packed = self.packed.addr
  deleted = sparse[eid]
  last    = sparse[u32(packed[self.high])]
  swap(packed[deleted], packed[last])
  swap(sparse[u32(packed[deleted])], sparse[u32(packed[last])])
  sparse[eid] = Ent.Nil
  dec self.count


proc has*(self: var EntsPack, entityId: SomeNumber): bool {.inline.} =
  self.sparse[entityId] < Ent.Nil


proc has*(self: var EntsPack, entity: Ent): bool {.inline.} =
  self.sparse[entity.id] < Ent.Nil


proc reset*(self: var EntsPack) =
  for i in 0..self.sparse.high:
    self.sparse[i] = Ent.Nil
  self.packed.setLen(0)
  self.count  = 0


#------------------------------------------------------------------------------------------
# @api ecs entity groups
#------------------------------------------------------------------------------------------
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
  var nextGroup = findGroup(reg, cmask)
  if nextGroup == EntityGroup.Nil:
    nextGroup  = mreg.entityGroups.append(make(EntityGroupObj))
    nextGroup.get.cmask = cmask
    nextGroup.get.ents  = initEnts()
    for cid in cmask.maskAll.incl:
      reg.cgroups.grow(cid.int):
        reg.cgroups[cid].add(nextGroup)
    for cid in cmask.maskAll.excl:
       reg.cgroups.grow(cid.int):
        reg.cgroups[cid].add(nextGroup)
    for cid in cmask.maskAny.incl:
     reg.cgroups.grow(cid.int):
        reg.cgroups[cid].add(nextGroup)
    for cid in cmask.maskAny.excl:
      reg.cgroups.grow(cid.int):
        reg.cgroups[cid].add(nextGroup)
  result = nextGroup


proc add(group: EntityGroup, eid: EcsInt) {.inline.} =
  group.get.ents.add(eid)


proc delete(group: EntityGroup, eid: EcsInt) {.inline.} =
  group.get.ents.delete(eid)


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
proc {pname}*(entity: Ent|EId): ptr {tname} {{.inline.}} =
  result = component(entity, {tname})""")
  else:
    source = &("""
let {pname}_id* = int {tname}.Id
proc {pname}*(entity: Ent|EId): var int {{.inline.}} =
  component(entity, {tname})[].int""")
  result = parsestmt(source)


template GEN_ECS_COMPONENT_API(T: typedesc, cmode: int, initSize: int) =
  #------------------------------------------------------------------------------------------
  # @api component define
  #------------------------------------------------------------------------------------------
  type ctype    = typedesc[T]
  type CPtr     = ptr T
  type CStorage = object
    comps*: seq[T]
    ents*:   EntsPack
    active: bool

  proc growStorage(reg: Registry, _: ctype)
  proc setStorage(reg: Registry, _: ctype)
  proc deleteComponentEnd*(eid: EcsInt, _: ctype) {.inline.}

  let ctypeId: int = io.nextComponentId; inc io.nextComponentId
  var storages = initObjectContext(CStorage,0)
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


  template Component*(_: ctype, entity: Ent|EId): CPtr =
     storage.comps[storage.ents.sparse[entity.id]].addr


  template component(eid: EcsInt, _: ctype): CPtr =
     storage.comps[storage.ents.sparse[eid]].addr


  template component(entity: Ent|EId, _: ctype): CPtr =
     storage.comps[storage.ents.sparse[entity.id]].addr


  proc hasComponent*(eid: EcsInt, _: ctype): bool {.inline, discardable.} =
    storage.ents.sparse[eid] < Ent.Nil #self.ents.count


  proc growStorage(reg: Registry, _: ctype) =
    var storage = storages.grow(reg.id.int)
    if storage.active:
      return
    storage.ents = initEnts()
    storage.comps = newSeq[T](initSize)
    storage.active = true
    io.componentEnts.grow(ctypeId)
    reg.cgroups.grow(ctypeId)


  proc setStorage(reg: Registry, _: ctype) =
    storages.setCurrent(reg.id.int)
    storage = storages.current.addr
    io.componentEnts[ctypeId] = storage.ents.addr

  
  gen_api_component(T, cmode)
  
  
  #------------------------------------------------------------------------------------------
  # @api component
  #------------------------------------------------------------------------------------------
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
    io[eid, EntityComps].del(T.Id)
    deleteComponentEnd(eid, ctype)
    updateGroups(eid, ctypeId)


  #------------------------------------------------------------------------------------------
  # @api component & segment public
  #------------------------------------------------------------------------------------------
  when cmode == AS_COMPONENT:
    proc get*(self: Ent|EId, _: ctype): CPtr {.discardable, inline.} =
      if hasComponent(self.id, ctype): return component(self.id, ctype)
      result = storage.comps[addComponent(self.id, ctype)].addr
      updateGroups(self.id, ctypeId)


    proc add*(builder: var EntityBuilder, _: ctype): CPtr {.discardable,inline.} =
      result = storage.comps[addComponent(builder.ent.id, ctype)].addr


    proc remove*(self: Ent|EId, _: ctype) {.inline.} =
      deleteComponentBegin(self.id, ctype)


  when cmode == AS_TAG:
    proc `+` *(a, b: T): T {.borrow.}
    proc `-` *(a, b: T): T {.borrow.}


    proc put*(self: Ent|EId, _: ctype, amount: int = 1) {.inline.} =
      if not hasComponent(self.id, ctype):
        discard addComponent(self.id, ctype)
      let slot = component(self.id, ctype)
      slot[] = amount.T
  

    proc add*(builder: var EntityBuilder, _: ctype, amount: int) =
      builder.ent.put(ctype,amount)


    proc inc*(self: Ent|EId, _: ctype){.inline.} =
      if not hasComponent(self.id, ctype):
        discard addComponent(self.id, ctype)
      let slot = component(self.id, ctype)
      slot[].int += 1


    proc inc*(self: Ent|EId, _: ctype, amount: int) =
      # todo: assert, amount can't be smaller than 1
      if not hasComponent(self.id, ctype):
        discard addComponent(self.id, ctype)
      var slot = component(self.id, ctype)
      slot[].int += amount
   
   
    proc remove*(self: Ent|EId, _: ctype) {.inline.} =
      deleteComponentBegin(self.id, ctype)


    proc dec*(self: Ent|EId, _: ctype){.inline.} =
      let slot = component(self.id, ctype)
      slot[].int -= 1
      if slot[].int <= 0:
        remove(self, ctype)


    proc dec*(self: Ent|EId, _: ctype, amount: int) =
      let slot = component(self.id, ctype)
      slot[].int -= amount
      if slot[].int <= 0:
        remove(self, ctype)


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


template genComponent*(api: EcsAPI; ctype: typed, initSize: static int = 0): untyped =
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


proc count*(system: System): int =
    system.get.group.get.ents.count.int


iterator entities*(system: System): EId {.inline.} =
  let system = system.get.addr
  let group = system.group.get.addr
  var index = group.ents.count
 # if system.rules.len == 0:
  while 0 < index:
    dec index
    yield group.ents.packed[index]
  # else:
  #   let rules = system.rules.addr
  #   while 0 < index:
  #     dec index
  #     let e = group.ents.packed[index]
  #     block iter:
  #       for rule in rules[].mitems:
  #         if rule(e) == false:
  #           break iter
  #       yield e


#------------------------------------------------------------------------------------------
# @api ecs system builder
#------------------------------------------------------------------------------------------
proc system*(api: EcsBuilder, reg: Registry): var SystemBuilder =
  var builder {.global.}: SystemBuilder = SystemBuilder()
  builder.system = make(SystemObj)
  let msystem = builder.system.get.addr
  msystem.reg = reg
  builder


proc system*(api: EcsBuilder, reg: Registry, tag: string): var SystemBuilder =
  var builder {.global.}: SystemBuilder = SystemBuilder()
  builder.system = io.sys.get(tag & $reg.id)
  let msystem = builder.system.get.addr
  msystem.reg = reg
  builder


proc withAll(builder: var SystemBuilder, mask: ComponentMaskPart): var SystemBuilder =
  builder.system.get.mask.maskAll = mask
  builder


proc withAny(builder: var SystemBuilder, mask: ComponentMaskPart): var SystemBuilder =
  builder.system.get.mask.maskAny = mask
  builder


template with*(builder: var SystemBuilder, ctypes: varargs[untyped]): var SystemBuilder =
  withAll(builder, gen_system_component_mask(maskAll, ctypes))


template withAny*(builder: var SystemBuilder, ctypes: varargs[untyped]): var SystemBuilder =
  withAny(builder, gen_system_component_mask(maskAny, ctypes))


# proc rule*(builder: var SystemBuilder, pred: proc(e: EId): bool {.closure.}): var SystemBuilder =
#   builder.system.get.rules.add(pred)
#   builder


proc build*(builder: var SystemBuilder): System =
  let reg = builder.system.get.reg
  builder.system.get.group = getGroup(builder.system.get.reg, builder.system.get.mask)
  builder.system

