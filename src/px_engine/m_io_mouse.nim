import px_engine/pxd/api
import px_engine/pxd/m_math
import px_engine/pxd/m_inputs
import px_engine/pxd/m_render
import px_engine/m_io


#------------------------------------------------------------------------------------------
# @api mouse
#------------------------------------------------------------------------------------------
proc mousePosition*(api: IoAPI): Vec3 =
  let mx  = pxd.events.input.mouseX
  let my  = pxd.events.input.mouseY
  # normalize
  let nmx = mx / io.app.viewport.w.int
  let nmy = my / io.app.viewport.h.int
  # normalize device coords
  let ndcx = (nmx*2)-1
  let ndcy = 1 - (nmy*2)
  result.x = ndcx
  result.y = ndcy
  result.z = 0
  var r1 = mul(inverse(pxd.render.frame.uproj),pxd.render.frame.uview)
  result = mul(r1, vec(ndcx,ndcy,0,1))

