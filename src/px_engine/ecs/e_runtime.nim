import px_engine/m_pxd
import definition/types
import c_runtime


proc obj*(api: PxdCreateAPI, reg: Registry, position: Vec3, rotation: Vec3): Object =
  let entity  = pxd.ecs.entity(reg)
  let cobject    = entity.get CObject
  let ctransform = entity.get CTransform
  ctransform.rotation = rotation
  ctransform.position = position
  result = Object entity


proc obj*(api: PxdCreateAPI, position: Vec3, rotation: Vec3): Object =
  let reg = pxd.ecs.getRegistry()
  obj(api, reg, position, rotation)


proc camera*(api: PxdCreateAPI, cfg: CameraDef, pos: Vec3): Camera =
  result = Camera pxd.create.obj(pos, vec3(0,0,0))
  let ccamera = result.get CCamera
  ccamera.projection = cfg.projection
  ccamera.zoom       = if cfg.zoom == 0.0: 1 else: cfg.zoom
  ccamera.fov        = cfg.fov
  ccamera.orthosize  = cfg.orthosize
  ccamera.planeFar   = cfg.planeFar
  ccamera.planeNear  = cfg.planeNear
  ccamera.matrixView = matrixIdentity()


proc camera*(api: PxdCreateAPI, cfg: CameraDef): Camera =
  result = camera(api, cfg, vec3(0,0,-100))