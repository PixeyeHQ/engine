import px_engine/m_pxd
import components_d
import c_camera
import e_object


proc camera*(api: PxdCreateAPI, cfg: ConfigCamera, pos: Vec3): Camera =
  result = Camera pxd.create.obj(pos, vec3(0,0,0))
  let ccamera = result.get CCamera
  ccamera.projection = cfg.projection
  ccamera.zoom       = if cfg.zoom == 0.0: 1 else: cfg.zoom
  ccamera.fov        = cfg.fov
  ccamera.orthosize  = cfg.orthosize
  ccamera.planeFar   = cfg.planeFar
  ccamera.planeNear  = cfg.planeNear
  ccamera.matrixView = matrixIdentity()


proc camera*(api: PxdCreateAPI, cfg: ConfigCamera): Camera =
  result = camera(api, cfg, vec3(0,0,-100))
