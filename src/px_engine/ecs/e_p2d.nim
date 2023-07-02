import px_engine/m_pxd
import definition/types
import c_runtime
import c_p2d


proc sprite*(api: P2DCreateAPI, reg: Registry, sprite: Sprite, position: Vec3, rotation: Vec3): Object =
  let entity  = pxd.ecs.entity(reg)
  let cobject    = entity.get CObject
  let ctransform = entity.get CTransform
  let csprite    = entity.get CSprite
  ctransform.rotation = rotation
  ctransform.position = position
  csprite.color       = cwhite
  csprite.data        = sprite
  result = Object entity


proc sprite*(api: P2DCreateAPI, sprite: Sprite, position: Vec3, rotation: Vec3): Object =
  let reg = pxd.ecs.getRegistry()
  sprite(api, reg, sprite, position, rotation)
