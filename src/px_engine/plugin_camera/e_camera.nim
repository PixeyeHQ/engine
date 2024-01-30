import ../px_engine_pxd
import ../px_engine_vars
import ../px_engine_components


type
  ProjectionKind* = enum
    Perspective,
    Orthographic
  CameraParams* = object
    projection*: ProjectionKind
    orthosize*: float
    fov*: float
    planeNear*: float
    planeFar*: float
    viewportKind*: int
    zoom*: float
  Camera* = ref object of EntityObj
    matrixView*: Matrix
    matrixProj*: Matrix
    matrixViewInversed*: Matrix
    matrixProjInversed*: Matrix
    projection*: ProjectionKind
    zoom*: float
    orthosize*: float
    fov*: float
    planeNear*: float
    planeFar*: float
    aspectRatio*: float
    viewportKind*: int


let defaultReg = pxd.ecs.getRegistry()


proc init(self: Camera, params: CameraParams, reg: Registry) =
  init(self, reg)
  self.get(Transform)
  self.projection = params.projection
  self.zoom       = if params.zoom == 0.0: 1 else: params.zoom
  self.fov        = params.fov
  self.orthosize  = params.orthosize
  self.planeFar   = params.planeFar
  self.planeNear  = params.planeNear
  self.matrixView = matrixIdentity()


proc newCamera*(api: CreateAPI, params: CameraParams, reg: Registry = defaultReg): Camera =
  result = Camera()
  init(result, params, reg)


proc newCamera2D*(api: CreateAPI, reg: Registry = defaultReg): Camera =
  result = api.newCamera(CameraParams(
    orthosize: 8,
    planeNear: 0.1,
    planeFar: 1000,
    projection: Orthographic), reg)


proc target*(api: RenderAPI, camera: Camera) =
  pxd.render.flush()
  pxd.render.frame.umvp.identity()
  pxd.render.viewport(pxd.vars.app_screen_w, pxd.vars.app_screen_h)
  let transform   = camera.transform
  let translation = transform.getPositionMatrix()
  let rotation    = transform.getRotationMatrix()
  let aspect      = pxd.vars.runtime_screen_ratio
  camera.matrixView = matrixIdentity()
  camera.matrixView = multiply(camera.matrixView, rotation)
  camera.matrixView = multiply(camera.matrixView, translation)
  camera.matrixViewInversed = camera.matrixView.inverse()
  pxd.render.frame.uview     = camera.matrixView 
  let n = camera.planeNear
  let f = camera.planeFar
  if camera.projection == ProjectionKind.Perspective:
    discard
  else:
    let h = camera.orthosize * camera.zoom
    let w = h * aspect
    pxd.render.frame.ppu = 1.0
    pxd.render.frame.umvp.ortho(-w,w,-h,h,n,f)
    pxd.render.frame.uproj = pxd.render.frame.umvp
    pxd.render.frame.umvp = multiply(pxd.render.frame.umvp, camera.matrixViewInversed)


proc target*(api: RenderAPI, camera: Camera, x: int, y: int) =
  pxd.render.flush()
  pxd.render.frame.umvp.identity()
  pxd.render.viewport(x, y)
  let transform   = camera.transform
  let translation = transform.getPositionMatrix()
  let rotation    = transform.getRotationMatrix()
  let aspect      = pxd.vars.runtime_screen_ratio
  camera.matrixView = matrixIdentity()
  camera.matrixView = multiply(camera.matrixView, rotation)
  camera.matrixView = multiply(camera.matrixView, translation)
  camera.matrixViewInversed = camera.matrixView.inverse()
  pxd.render.frame.uview     = camera.matrixView 
  let n = camera.planeNear
  let f = camera.planeFar
  if camera.projection == ProjectionKind.Perspective:
    discard
  else:
    let h = camera.orthosize * camera.zoom
    let w = h * aspect
    pxd.render.frame.ppu = 1.0
    pxd.render.frame.umvp.ortho(-w,w,-h,h,n,f)
    pxd.render.frame.uproj = pxd.render.frame.umvp
    pxd.render.frame.umvp = multiply(pxd.render.frame.umvp, camera.matrixViewInversed)