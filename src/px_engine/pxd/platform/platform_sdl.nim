import std/times
import px_engine/vendor/sdl
import px_engine/pxd/definition/api
import px_engine/pxd/m_debug
import px_engine/pxd/m_vars
import platform_d

#------------------------------------------------------------------------------------------
# @api platform define
#------------------------------------------------------------------------------------------
type PlatformState = object
  window: pointer
  timeStart: uint64
  timeFreq:  uint64


var platformState = PlatformState()
let io            = pxd.io


proc state (api: PlatformAPI): var PlatformState =
  platformState


#------------------------------------------------------------------------------------------
# @api platform
#------------------------------------------------------------------------------------------
proc reportInitPlatform(api: DebugAPI) =
  var osname: string
  let time = now().format("yyyy-MM-dd")
  when defined(windows): osname = "Windows"
  elif defined(macosx): osname = "Macos"
  elif defined(linux): osname = "linux"
  let message = &"\n System: {osname}\n Started: {time}"
  pxd.vars.get("runtime.initMessage", string)[] = message


proc initGl*(api: PlatformAPI): pointer {.discardable.} =
  discard sdl.glSetAttribute(sdl.GL_CONTEXT_MAJOR_VERSION, 4)
  discard sdl.glSetAttribute(sdl.GL_CONTEXT_MINOR_VERSION, 6)
  result = sdl.glGetProcAddress
  if result == nil:
    pxd.debug.fatal("Platform", &"Could not load GL.\n{sdl.getError()}")


proc init*(api: PlatformAPI) =
  if sdl.init(sdl.INIT_VIDEO and sdl.INIT_AUDIO) < 0:
    pxd.debug.fatal("Platform", &"Could not initialize SDL.\n{sdl.getError()}")
  pxd.debug.reportInitPlatform()
  api.state.timeStart = sdl.getPerformanceCounter()
  api.state.timeFreq  = sdl.getPerformanceFrequency()


proc createWindow*(api: PlatformAPI): pointer {.discardable.} =
  let title  = pxd.vars.get("app.title", string)[]
  let width  = pxd.vars.get("app.window.w", int)[]
  let height = pxd.vars.get("app.window.h", int)[]
  let windowFlags: u32 = sdl.WindowResizable or sdl.WindowShown or sdl.WindowOpenGL
  api.state.window = sdl.createWindow(title.cstring, WINDOWPOS_UNDEFINED, WINDOWPOS_UNDEFINED, width, height, windowFlags)
  result = api.state.window
  if result == nil:
    pxd.debug.fatal("Platform", &"Could not initialize window.\n{sdl.getError()}")
  pxd.vars.put("app.vars.window.w", width)
  pxd.vars.put("app.vars.window.h", height)


proc createGlContext*(api: PlatformAPI): pointer {.discardable.} =
  result = glCreateContext(api.state.window)


proc getTimeTicks*(api: PlatformAPI): float64 =
  sdl.getPerformanceCounter().float64 / api.state.timeFreq.float64


proc getTime*(api: PlatformAPI): float64 =
  ((sdl.getPerformanceCounter() - api.state.timeStart).float64 / api.state.timeFreq.float64)


proc sleep*(api: PlatformAPI, time: float64) =
  sdl.delay(time.uint32)


proc swapWindow*(api: PlatformAPI) =
  sdl.glSwapWindow(api.state.window)


proc setVsync*(api: PlatformAPI, mode: bool) =
  if mode:
    discard sdl.glSetSwapInterval(1)
  else:
    discard sdl.glSetSwapInterval(0)


proc setWindowTitle*(api: PlatformAPI, title: string) =
  sdl.setWindowTitle(api.state.window, title)


#------------------------------------------------------------------------------------------
# @api platform events
#------------------------------------------------------------------------------------------

template handleEvents*(api: PlatformAPI, proc_on_event_engine: untyped, proc_on_event_game: untyped) =
  block: # poll inputs
    let ev_input = pxd.events.input.addr
    for index in 0..<SCANCODES_ALL:
      ev_input.keyStateDown[index] = 0
      ev_input.keyStateUp[index]   = 0
    let kbdState = sdl.getKeyboardState(nil)
    let mbState  = sdl.getMouseState(ev_input.mouseX.addr, ev_input.mouseY.addr)
    block: # mouse
      for index in 1..<SCANCODES_MOUSE:
        let keyIndex = SCANCODES_MOUSE_BEGIN + index
        let wasDown  = ev_input.keyState[keyIndex]
        ev_input.keyState[keyIndex] = (sdl.button(index) and mbState.int32).float
        let isDown = ev_input.keyState[keyIndex]
        if 0 < wasDown and isDown == 0:
          ev_input.keyStateUp[keyIndex] = 1
        elif wasDown == 0 and 0 < isDown:
          ev_input.keyStateDown[keyIndex] = 1
    block: # keyboard
      for index in 0..<SCANCODES_MOUSE_BEGIN:
        let wasDown = ev_input.keyState[index]
        ev_input.keyState[index] = kbdState[index].float
        let isDown = ev_input.keyState[index]
        if 0 < wasDown and isDown == 0:
          ev_input.keyStateUp[index] = 1
        elif wasDown == 0 and 0 < isDown:
          ev_input.keyStateDown[index] = 1 
  block: # poll events
    var e: sdl.Event
    while sdl.pollEvent(addr(e)) > 0:
      case e.kind:
        of sdl.Quit:
          io.app.keepRunning = false
        of sdl.WindowEvent:
          if e.window.event == WindowEventId.WINDOWEVENT_SIZE_CHANGED:
            pxd.events.windowResize.width  = e.window.data1
            pxd.events.windowResize.height = e.window.data2
            onCompile(proc_on_event_engine(pxd.events.windowResize.eventId))
            onCompile(proc_on_event_game(pxd.events.windowResize.eventId))
        of sdl.MouseMotion:
          let ev_input = pxd.events.input.addr
          ev_input.mouseX = e.button.x
          ev_input.mouseY = e.button.y
        of sdl.MouseButtonDown:
          if e.button.button == 1: # left
            onCompile(proc_on_event_engine(pxd.events.mouse.eventId))
            onCompile(proc_on_event_game(pxd.events.mouse.eventId))
          discard
        else:
          discard