import px_engine/m_pxd
import components_d
import c_object
import c_transform


proc obj*(api: PxdCreateAPI, reg: Registry, position: Vec3, euler: Vec3): Object =
  let entity  = pxd.ecs.entity(reg)
  let cobject    = entity.get CObject
  let ctransform = entity.get CTransform
  ctransform.euler    = euler
  ctransform.position = position
  result = Object entity


proc obj*(api: PxdCreateAPI, position: Vec3, euler: Vec3): Object =
  let reg = pxd.ecs.getRegistry()
  obj(api, reg, position, euler)