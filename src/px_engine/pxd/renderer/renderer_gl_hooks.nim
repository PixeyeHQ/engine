import px_engine/vendor/stb_image
import px_engine/pxd/definition/api
import px_engine/pxd/m_debug
import renderer_gl_d

let debug = pxd.debug
let io    = pxd.io


var render      = RenderAPI_Internal(api_o)
var renderFrame = RenderFrame()


proc internal*(api: RenderAPI): RenderAPI_Internal =
  render


proc frame*(api: RenderAPI): var RenderFrame {.inline.} =
  ## Renderer frame state. 
  renderFrame