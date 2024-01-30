import std/[times, strformat, os]
import ../[api, m_vars, m_debug]
import ../../vendors/sdl


type
  PlatformState = object
    window: pointer
    timeStart: uint64
    timeFreq:  uint64
var
  platformState = PlatformState()



#------------------------------------------------------------------------------------------
# @api platform
#------------------------------------------------------------------------------------------
proc state(api: PlatformAPI): var PlatformState = platformState


proc reportInitPlatform(api: DebugAPI) =
  var osname: string
  let time = now().format("yyyy-MM-dd")
  when defined(windows): osname = "Windows"
  elif defined(macosx): osname = "Macos"
  elif defined(linux): osname = "linux"
  let message = &"\n SYSTEM: {osname}\n Started: {time}"
  pxd.vars.get("runtime.initMessage", string)[] = message


proc initGl*(api: PlatformAPI): pointer {.discardable.} =
  discard sdl.glSetAttribute(sdl.GL_CONTEXT_MAJOR_VERSION, 4)
  discard sdl.glSetAttribute(sdl.GL_CONTEXT_MINOR_VERSION, 6)
  result = sdl.glGetProcAddress
  if result == nil:
    pxd.debug.fatal(&"PLATFORM: Could not load GL.\n{sdl.getError()}")


proc init*(api: PlatformAPI) =
  if sdl.init(sdl.INIT_VIDEO and sdl.INIT_AUDIO) < 0:
    pxd.debug.fatal(&"PLATFORM: Could not initialize SDL.\n{sdl.getError()}")
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
    pxd.debug.fatal(&"PLATFORM: Could not initialize window.\n{sdl.getError()}")
  pxd.vars.put("app.vars.window.w", width)
  pxd.vars.put("app.vars.window.h", height)


proc createGlContext*(api: PlatformAPI): pointer {.discardable.} =
  result = glCreateContext(api.state.window)


proc swapWindow*(api: EngineAPI) =
  sdl.glSwapWindow(platformState.window)


proc getTimeTicks*(api: TimerAPI): float64 =
  sdl.getPerformanceCounter().float64 / platformState.timeFreq.float64


proc getTime*(api: TimerAPI): float64 =
  ((sdl.getPerformanceCounter() - platformState.timeStart).float64 / platformState.timeFreq.float64)


proc sleep*(api: TimerAPI, time: float64) =
  sdl.delay(time.uint32)


proc setVsync*(api: WindowAPI, mode: bool) =
  if mode:
    discard sdl.glSetSwapInterval(1)
  else:
    discard sdl.glSetSwapInterval(0)


proc setTitle*(api: WindowAPI, title: string) =
  sdl.setWindowTitle(platformState.window, title)


proc getWindow*(api: WindowAPI): pointer =
  platformState.window


#------------------------------------------------------------------------------------------
# @api platform events
#------------------------------------------------------------------------------------------
var eventsCallbacks = newSeq[proc(ev: sdl.Event)]()


proc addCallback*(api: EventAPI, proc_callback: proc(ev: sdl.Event)) =
  # Very important, provide events to plugins such as IMGUI
  eventsCallbacks.add(proc_callback)


template handleEvents*(api: PlatformAPI, procAppEvents: untyped) =
  {.push warning: [HoleEnumConv] off.}
  block: # poll inputs
    let ev_input = pxd.events.input.addr
    for index in 0..<SCANCODES_ALL:
      ev_input.keyStateDown[index] = 0
      ev_input.keyStateUp[index]   = 0
    let kbdState = sdl.getKeyboardState(nil)
    let mbState  = sdl.getMouseState(pxd.vars.mouse.x.addr, pxd.vars.mouse.y.addr)
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
          onCompile(procAppEvents(AppEvent(kind: EKeyUp, input: InputKeyObj(key: index))))
        elif wasDown == 0 and 0 < isDown:
          ev_input.keyStateDown[index] = 1
          onCompile(procAppEvents(AppEvent(kind: EKeyDown, input: InputKeyObj(key: index))))
        if isDown > 0:
          onCompile(procAppEvents(AppEvent(kind: EKey, input: InputKeyObj(key: index))))
  {.pop.}
  block: # poll events
    var e: sdl.Event
    while sdl.pollEvent(addr(e)) > 0:
      case e.kind:
        of sdl.Quit:
          pxd.vars.app_wantsQuit = true
        of sdl.WindowEvent:
           if e.window.event == WindowEventId.WINDOWEVENT_SIZE_CHANGED:
            pxd.vars.app_screen_w = e.window.data1
            pxd.vars.app_screen_h = e.window.data2
            pxd.vars.runtime_screen_ratio = float pxd.vars.app_screen_w / pxd.vars.app_screen_h
            onCompile(procAppEvents(AppEvent(kind: EWindowResize)))
        of sdl.MouseMotion:
          onCompile(procAppEvents(AppEvent(kind: EMouseMotion)))
        else:
          discard
      for cb in eventsCallbacks:
       cb(e)