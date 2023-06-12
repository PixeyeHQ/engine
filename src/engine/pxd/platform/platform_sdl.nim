import std/times
import engine/vendor/sdl
import engine/m_io
import engine/pxd/api
import engine/pxd/m_debug
import engine/pxd/m_vars
import engine/pxd/inputs/inputs_event
import platform_d

#------------------------------------------------------------------------------------------
# @api platform define
#------------------------------------------------------------------------------------------
type PlatformState = object
  window: pointer
  timeStart: u64
  timeFreq:  u64


var platformState = PlatformState()


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
  io.vars.get("runtime.initMessage", string)[] = message


proc initGl*(api: PlatformAPI): pointer {.discardable.} =
  discard sdl.glSetAttribute(sdl.GL_CONTEXT_MAJOR_VERSION, 4)
  discard sdl.glSetAttribute(sdl.GL_CONTEXT_MINOR_VERSION, 6)
  result = sdl.glGetProcAddress
  if result == nil:
    debug.fatal("Platform", &"Could not load GL.\n{sdl.getError()}")


proc init*(api: PlatformAPI) =
  if sdl.init(sdl.INIT_VIDEO and sdl.INIT_AUDIO) < 0:
    debug.fatal("Platform", &"Could not initialize SDL.\n{sdl.getError()}")
  debug.reportInitPlatform()
  api.state.timeStart = sdl.getPerformanceCounter()
  api.state.timeFreq  = sdl.getPerformanceFrequency()


proc createWindow*(api: PlatformAPI): pointer {.discardable.} =
  let title  = io.vars.get("app.title", string)[]
  let width  = io.vars.get("app.window.w", int)[]
  let height = io.vars.get("app.window.h", int)[]
  let windowFlags: u32 = sdl.WindowResizable or sdl.WindowShown or sdl.WindowOpenGL
  api.state.window = sdl.createWindow(title.cstring, WINDOWPOS_UNDEFINED, WINDOWPOS_UNDEFINED, width, height, windowFlags)
  result = api.state.window
  if result == nil:
    debug.fatal("Platform", &"Could not initialize window.\n{sdl.getError()}")
  io.vars.put("app.vars.window.w", width)
  io.vars.put("app.vars.window.h", height)
  io.app.screen.w = width
  io.app.screen.h = height


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
        else:
          discard