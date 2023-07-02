import px_engine/m_pxd
import definition/types
import c_runtime


proc mode*(api: RenderAPI, camera: Camera) =
  pxd.engine.renderState()
  pxd.render.frame.umvp.identity()
  viewport(pxd.io.app.screen.w, pxd.io.app.screen.h)
  let ccamera    = camera.ccamera
  let ctransform = camera.ctransform
  let translation = ctransform.getPositionMatrix()
  let rotation    = ctransform.getRotationMatrix()
  let aspect      = pxd.io.app.aspectRatio()
  ccamera.matrixView = matrixIdentity()
  ccamera.matrixView = multiply(ccamera.matrixView, rotation)
  ccamera.matrixView = multiply(ccamera.matrixView, translation)
  ccamera.matrixViewInversed = ccamera.matrixView.inverse()
  pxd.render.frame.uview     = ccamera.matrixView 
  let n = ccamera.planeNear
  let f = ccamera.planeFar
  if ccamera.projection == ProjectionKind.Perspective:
    discard
  else:
    let h = ccamera.orthosize * ccamera.zoom
    let w = h * aspect
    pxd.render.frame.umvp.ortho(-w,w,-h,h,n,f)
    pxd.render.frame.uproj = pxd.render.frame.umvp
    pxd.render.frame.umvp = multiply(pxd.render.frame.umvp, ccamera.matrixViewInversed)