import px_engine
import px_dearimgui/dearimgui as imgui
export imgui

when defined(sdl):
  import px_dearimgui/[impl_sdl]
when defined(opengl):
  import px_dearimgui/[impl_opengl]

type
  ImguiAPI* = distinct API_Obj

var
  api_imgui = ImguiAPI(api_o)
  context: ptr ImGuiContext
  window: pointer


proc imgui*(api: PxdAPI): ImguiAPI = api_imgui


proc init*(api: ImguiAPI) =
  context = igCreateContext(nil)
  window = pxd.window.getWindow()
  when defined(sdl):
    doAssert igSDL2InitForOpenGL(window, nil)
    pxd.events.addCallback(igSDL2_ProcessEvent)
  when defined(opengl):
    doAssert igOpenGL3Init()
  igStyleColorsCherry()


proc imgui*(api: RenderAPI) =
  pxd.render.flush()
  igRender()
  igOpenGL3RenderDrawData(igGetDrawData())
  pxd.render.flush()


proc newFrame*(api: ImguiAPI) =
  when defined(opengl): igOpenGL3NewFrame()
  when defined(sdl):    igSDL2NewFrame(window, pxd.timer.state.delta)
  igNewFrame()


# template draw*(api: ImguiAPI, code: untyped) =
#   block: # order matters
#     when defined(opengl): igOpenGL3NewFrame()
#     when defined(sdl):    igSDL2NewFrame(window, pxd.timer.state.delta)
#     igNewFrame()
#     code
#     igRender()


proc shutdown*(api: ImguiAPI) =
  igOpenGL3Shutdown()
  igSDL2Shutdown()
  context.igDestroyContext()



proc startup_plugin_imgui*() =
  pxd.imgui.init()


proc frame_begin_plugin_imgui*() =
  pxd.imgui.newFrame()


proc draw_plugin_imgui*() =
  pxd.render.imgui()


proc shutdown_plugin_imgui*() =
  pxd.imgui.shutdown()