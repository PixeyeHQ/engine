import px_engine/vendor/gl
import px_engine/vendor/stb_image
import px_engine/pxd/definition/api
import px_engine/pxd/m_math
import px_engine/pxd/m_io
import renderer_gl_p2d
import renderer_gl


let io = pxd.io
#------------------------------------------------------------------------------------------
# @api render
#------------------------------------------------------------------------------------------
proc renderState*(api: EngineAPI) =
  p2d.executeRender()


template draw*(api: PxdAPI, code: untyped) = 
  block:
    code


proc clear*(api: RenderAPI, r,g,b: f64) =
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
  pxd.engine.renderState()
  let w  = io.app.screen.w.f64
  let h  = io.app.screen.h.f64
  var m = getScreenMatrix()
  pxd.render.frame.umvp.identity()
  pxd.render.frame.umvp.ortho(0,w,0,h,0.01,1000)
  pxd.render.frame.umvp = multiply(pxd.render.frame.umvp, m)
  glViewport(0,0,w.int,h.int)


proc viewport*(x: int, y: int) =
  let aspectRatio = io.app.aspectRatio()
  var aspectWidth  = x.f32
  var aspectHeight = aspectWidth / aspectRatio
  if aspectHeight > y.f32:
    aspectHeight = y.f32
    aspectWidth  = aspectHeight * aspectRatio
  let viewportx = i32(x / 2 - aspectWidth.f32 / 2)
  let viewporty = i32(y / 2 - aspectHeight.f32 / 2)
  glViewport(viewportx,viewporty,aspectWidth.int,aspectHeight.int)
  io.app.viewport.w = aspectWidth - viewportx.f64
  io.app.viewport.h = aspectHeight - viewporty.f64
  #   of vp_fit:
  #     let aspectRatio  = global.getAspectRatio()
  #     var aspectWidth  = x.f32
  #     var aspectHeight = aspectWidth / aspectRatio
  #     if aspectHeight > y.f32:
  #       aspectHeight = y.f32
  #       aspectWidth  = aspectHeight * aspectRatio
  #     let viewportx = i32(x / 2 - aspectWidth.f32 / 2)
  #     let viewporty = i32(y / 2 - aspectHeight.f32 / 2)
  #     rdViewport(viewportx,viewporty,aspectWidth.int,aspectHeight.int)
  #   of vp_screen: # Stretch Aspect = Keep Width
  #     let aspectRatio  = 1920.0/1080.0
  #     var aspectWidth  = x.f32
  #     var aspectHeight = aspectWidth / aspectRatio
  #     if aspectHeight > y.f32:
  #       aspectHeight = y.f32
  #       aspectWidth  = aspectHeight * aspectRatio
  #     rdViewport(0,0,aspectWidth.int,aspectHeight.int)



  
    #ccamera.matrixProj.ortho(-w,w,-h,h,n,f)
    #pxd.render.frame.umvp.ortho(-w,w,h,h,n,f)
    #pxd.render.frame.umvp = multiply(pxd.render.frame.umvp, ccamera.matrixView)
  #ccamera.matrixProjInversed = ccamera.matrixProj.inverse()
  #glViewport(0,0,w.int,h.int)


    # of vp_extend:
    #   let aspectRatio  = global.getAspectRatio()
    #   var aspectWidth  = x.f32
    #   var aspectHeight = aspectWidth / aspectRatio
    #   if aspectHeight > y.f32:
    #     aspectHeight = y.f32
    #     aspectWidth  = aspectHeight * aspectRatio
    #   let viewportx = i32(x / 2 - aspectWidth.f32 / 2)
    #   let viewporty = i32(y / 2 - aspectHeight.f32 / 2)
    #   rdViewport(viewportx,viewporty,aspectWidth.int,aspectHeight.int)


proc depthTest*(api: RenderAPI, mode: static bool) =
  pxd.engine.renderState()
  when mode == true:
    glEnable(GL_DEPTH_TEST)
  else:
    glDisable(GL_DEPTH_TEST)


# proc mode*(self: Ent) {.inline.} =
#   renderActiveBatch()
#   var ccamera = self.ccamera
#   ccamera.viewportKind = vp_extend.int
#   state.matrixProj = ccamera.matrixProj
#   state.matrixView = ccamera.matrixViewInversed
#   viewport(window_w[],window_h[],vp_extend)
#   let batch  = getActiveBatch()
#   let shader = batch.shader
#   rdUse(shader)
#   shader.set_uniform_m4f("uproj",state.matrixProj)
#   shader.set_uniform_m4f("uview",state.matrixView)
#   rdStop(shader)