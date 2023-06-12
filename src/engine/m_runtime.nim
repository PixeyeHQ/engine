import engine/px
import engine/m_io
import engine/m_pxd
import engine/m_p2d
import std/os
import std/strformat


proc reportAppInitialized(api: DebugAPI) =
  let p1 = io.vars.get("runtime.initMessage",string)[]
  api.info &"Application initialized sucessfully!{p1}"


#------------------------------------------------------------------------------------------
# @api events
#------------------------------------------------------------------------------------------
proc onEvent*(api: EngineAPI, ev: EventId) {.inline.} =
  case ev:
    of EventWindowResize:
      io.app.screen.w = pxd.events.windowResize.width
      io.app.screen.h = pxd.events.windowResize.height
    else:
      discard


#------------------------------------------------------------------------------------------
# @api entry
#------------------------------------------------------------------------------------------
proc timestepBegin*(api: EngineAPI) {.inline.} =
  template trySnapDeltaTime(dt: var float32, ms: float32): untyped =
    ## Time snapping need to prevent sync issues and monitor stutternes without
    ## detecting vsync. We pretend that `deltatime` is always correct with fluctuations.
    if abs(dt-ms) < ms_fluctuation == true:
      dt = ms
  let timestate   = pxd.time.state.addr
  let timeElapsed = timestate.timeElapsed
  let time        = pxd.platform.getTime(); timestate.timeElapsed = time
  var dtUnscaled = time - timeElapsed
  trySnapDeltaTime(dtUnscaled, ms008)
  trySnapDeltaTime(dtUnscaled, ms016)
  trySnapDeltaTime(dtUnscaled, ms032)
  var dt = dtUnscaled * timestate.scale
  # Prevent time anomalies.
  # If delta time is less than 0 it means system timer reseted.
  # If delta time is anormaly high, we don't want to fast forward the game in a step.
  timestate.delta         = clamp(dt, 0, msgap)
  timestate.deltaUnscaled = clamp(dtUnscaled, 0, msgap)
  timestate.stepLag      += timestate.delta
  # Prevent spiral of doom scenario.
  timestate.stepLag = clamp(timestate.stepLag, 0, msgap)


proc timestepFinish*(api: EngineAPI) =
  let timestate = pxd.time.state.addr
  inc timestate.framesElapsed
  inc pxd.metrics.app.state.frames
  if io.app.vsync: return
  let fps         = io.app.fps; if fps < 0: return
  let timeElapsed = timestate.timeElapsed
  let ms          = 1.0 / fps.float
  let dt          = pxd.platform.getTime() - timeElapsed
  if dt < ms:
    pxd.platform.sleep((ms-dt)*1000) 


proc closeApp*(api: PxdAPI) =
  io.app.keepRunning = false


proc shouldRun*(api: EngineAPI): bool {.inline.} =
  io.app.keepRunning == true


proc init*(api: EngineAPI) {.inline.} =
  debug.init()
  io.init()
  pxd.render.init()
  engine.initAudio()
  p2d.initRenderer()
  pxd.platform.setVsync(io.app.settings.vsync[])
  debug.reportAppInitialized()


proc shutdown*(api: EngineAPI) {.inline.} =
  debug.shutdown()
  engine.shutdownAudio()

proc render(api: EngineAPI) {.inline.} =
  p2d.executeRender()
  pxd.platform.swapWindow()
  pxd.metrics.app.drawcalls = pxd.metrics.app.state.drawcalls
  pxd.metrics.app.state.drawcalls = 0

proc measureFps*(api: EngineAPI) {.inline.} =
  pxd.time.every(1.0, pm_seconds):
    let frames = pxd.metrics.app.state.frames.addr
    let ticks  = pxd.metrics.app.state.ticks.addr
    pxd.metrics.app.fps = int frames[]
    pxd.metrics.app.ups = int ticks[]
    frames[] = 0
    ticks[]  = 0


template run*(api: PxdAPI, code: untyped): untyped =
  let timeState = pxd.time.state.addr
  template loop(apiLoop: PxdAPI, gameOnEvent: untyped, codeLoop: untyped) =
    var dt {.inject.}: float
    block:
      template everyStep(apiStep: PxdAPI, codeStep: untyped) {.used.} =
        let ms = 1.0 / io.app.ups.float
        while ms <= timeState.stepLag:
          codeStep
          timeState.stepLag -= ms
          inc pxd.metrics.app.state.ticks
      while engine.shouldRun():
        engine.timestepBegin(); dt = timeState.delta
        pxd.platform.handleEvents(engine.onEvent, gameOnEvent)
        codeLoop
        engine.render()
        engine.timestepFinish()
        engine.measureFps()
  template loop(apiLoop: PxdAPI, codeLoop: untyped) {.dirty.} =
    loop(apiLoop, void, codeLoop)
  engine.init()
  code
  engine.shutdown()