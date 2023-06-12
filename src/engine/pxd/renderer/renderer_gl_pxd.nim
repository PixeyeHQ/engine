import engine/vendor/gl
import engine/vendor/stb_image
import engine/m_io
import engine/px
import engine/pxd/api
import engine/p2d/api
import engine/pxd/m_math
import renderer_gl_p2d
import renderer_gl


#------------------------------------------------------------------------------------------
# @api render
#------------------------------------------------------------------------------------------
template draw*(api: RenderAPI, code: untyped) = 
  block:
    code


proc clear*(api: RenderAPI, r,g,b: float) =
  glClearColor(r,g,b,1.0)
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)
  glClearDepth(1.0)


proc mode*(api: RenderAPI, _: SCREEN_MODE) =
  proc getScreenMatrix(): Matrix =
    var cameraPos {.global.} = vec3(0,0,100)
    var translation = matrixIdentity()
    translation.setPosition(cameraPos)
    result = matrixIdentity()
    result = multiply(result, translation)
    result.invert()


  let sw = io.app.settings.window.w[].float
  let sh = io.app.settings.window.h[].float
  let w  = io.app.screen.w.float
  let h  = io.app.screen.h.float
  let rw = clamp(w / sw, 0, 1)
  let rh = clamp(h / sh, 0, 1)
  if rh < rw:
    io.app.screen.ratio = rh
  else:
    io.app.screen.ratio = rw
  var m = getScreenMatrix()
  pxd.render.frame.umvp.ortho(0,w,0,h,0.01,1000)
  pxd.render.frame.umvp = multiply(pxd.render.frame.umvp, m)
  glViewport(0,0,w.int,h.int)


proc depthTest*(api: RenderAPI, mode: static bool) =
  p2d.executeRender()
  when mode == true:
    glEnable(GL_DEPTH_TEST)
  else:
    glDisable(GL_DEPTH_TEST)