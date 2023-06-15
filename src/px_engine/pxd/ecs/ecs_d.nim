import std/tables
import px_engine/pxd/api


type Ent*         = distinct u64


const EntLo*: u64 = 1 shl 32 - 1
const EntHi*: u64 = 1 shl 32
const ECS_ENTITY_VERSION_MAX*: u32 = 1 shl 32 - 1

const ECS_ENUM_ID*               = int 100_000
const ECS_ENTITY_MAX* {.define.} = 50_000
const ECS_ENTITY_CAP*            = ECS_ENTITY_MAX + 1

const AS_COMPONENT* = 0
const AS_TAG*       = 1
const AS_SEGMENT*   = 2


type EcsInt*   = u32
type CId*      = u16
type EId*      = distinct u32
type Registry* = distinct Handle
type EcsBuilder* = distinct object


type ComponentMaskPart* = object
  incl*: seq[CId]
  excl*: seq[CId]


type ComponentMask* = object
  maskAll*: ComponentMaskPart
  maskAny*: ComponentMaskPart


type EntsPack* = object
  sparse*: seq[EcsInt] # loosely packed pointers to dense elements. Example: 0,1,2,nil,3
  packed*: seq[EId]    # tightly packed ids of entities. Example: 0,1,2,4
  count*:  int


type Entity* = object
  id*:      u32
  version*: u32
type EntityComps* = seq[CId]
type EntityRegistry* = distinct Registry
type EntityRange* = object
  max*:  u32
  min*:  u32
  free*: u32
  next*: EcsInt

type SOA_EntityInfo* = object
  ## SOA strategy is preferable here according to benchmarks.
  entity*:      seq[Entity]
  entityComps*: seq[EntityComps]
  entityReg*:   seq[Registry]


type EntityBuilder* = object
  ent*: Ent
  reg*: Registry


type EntityGroupObj* = object
  cmask*:   ComponentMask
  ents*:    EntsPack


type EntityGroup* = distinct Handle


type SystemObj* = object
  mask*:  ComponentMask
  group*: EntityGroup
  reg*:   Registry
  #rules*: seq[proc(e: EId):bool{.closure.}]


type System* = distinct Handle


type SystemBuilder* = object
  system*: System


type RegistryObj* = object
  entityRange*:  EntityRange
  entityGroups*: seq[EntityGroup]
  entityTagged*: Table[string,Ent]
  cgroups*:      seq[seq[EntityGroup]]


proc Nil*(T: typedesc[EntityGroup]): EntityGroup = EntityGroup u32.high
template Nil*(T: typedesc[EId]|typedesc[Ent]): u32 = (ECS_ENTITY_MAX + 1).u32
template id* (self: EId): EcsInt = self.EcsInt


proc `=copy`*(dest: var RegistryObj; source: RegistryObj) {.error.}
proc `=copy`*(dest: var EntityGroupObj; source: EntityGroupObj) {.error.}


template EntSizeT*(self: Ent): u64 =
  self.u64
template EntSizeT*(self: u32): u64 =
  self.u64
