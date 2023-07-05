import px_engine


type CTransform = object
  x,y,z: float

type CObject = object
  id: int
  power: int

type CPawn = object
  id: int

type TagDamaged = distinct int

# Normally debug initialization and shutdown are called from pxd.run, but in this example we have to call them explicitly as we don't do pxd.run
pxd.debug.init()


pxd.ecs.genComponent(CTransform, ECS_ENTITY_MAX)
pxd.ecs.genComponent(CObject,    ECS_ENTITY_MAX)
pxd.ecs.genComponent(CPawn,      ECS_ENTITY_MAX)
pxd.ecs.genComponent(TagDamaged, ECS_ENTITY_MAX)


proc with*(builder: var EntityBuilder, ctype: ctransform_t, x,y,z: float): var EntityBuilder =
  let c = builder.add(ctype)
  c.x = x
  c.y = y
  c.z = z
  builder


proc with*(builder: var EntityBuilder, ctype: cobject_t, id: int, power: int): var EntityBuilder =
  let c = builder.add(ctype)
  c.id    = id
  c.power = power
  builder


proc with*(builder: var EntityBuilder, ctype: cpawn_t, id: int): var EntityBuilder =
  let c = builder.add(ctype)
  c.id = id
  builder


proc with*(builder: var EntityBuilder, ctype: tdamaged_t, amount: int): var EntityBuilder =
  builder.add(ctype,amount)
  builder


let reg  = pxd.ecs.getRegistry()


benchmark ECS_ENTITY_MAX, 1:
  profile "create":
    let e = pxd.ecs.entity(reg)
    e.get ctransform_t
    e.get cobject_t


benchmark 1, 1:
  profile "reset all":
    pxd.ecs.reset(reg)


let sys = pxd.ecs.builder.system(reg)
                     .with(CTransform,CObject,CPawn)
                     .build()


benchmark ECS_ENTITY_MAX, 1:
  profile "update system":
    for e in sys.entities():
      e.get ctransform_t
      e.get cobject_t


pxd.ecs.update() # normally ecs update works internally via pxd.run
pxd.debug.shutdown()

#[
  [*] 16k
  create: 0ms
  reset:  0.06ms
  update: 0.00350ms
  [*] 65k
  create: 1.1ms
  reset:  0.25ms
  update: 0.01420ms
  [*] 262k
  create: 4.7ms
  reset:  1.2ms
  update: 0.057ms
  [*] 1mln
  create: 18.4ms
  reset:  5.8ms
  update: 0.21ms
  [*] 2mln
  create: 36.5ms
  reset:  11ms
  update: 0.67ms
]#