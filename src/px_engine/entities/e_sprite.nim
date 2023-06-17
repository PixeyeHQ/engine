import px_engine/m_pxd
import px_engine/assets/asset_sprite
import components_d
import c_object
import c_transform
import c_sprite


proc sprite*(api: PxdCreateAPI, reg: Registry, sprite: Sprite, position: Vec3, euler: Vec3): Object =
  let entity  = pxd.ecs.entity(reg)
  let cobject    = entity.get CObject
  let ctransform = entity.get CTransform
  let csprite    = entity.get CSprite
  ctransform.euler    = euler
  ctransform.position = position
  csprite.color       = cwhite
  csprite.data        = sprite
  result = Object entity


proc sprite*(api: PxdCreateAPI, sprite: Sprite, position: Vec3, euler: Vec3): Object =
  let reg = pxd.ecs.getRegistry()
  sprite(api, reg, sprite, position, euler)