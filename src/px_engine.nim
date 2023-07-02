import std/os
import std/strformat


import px_engine/Px
export Px


import px_engine/m_pxd
export m_pxd except
  initRenderer,
  executeRender


import px_engine/m_ecs
export m_ecs


import px_engine/pxd/pods/pods as pxd_pods
export pxd_pods


import std/tables
export tables


const EventGame = EventId.Next(-1)


let io     = pxd.io
let debug  = pxd.debug
let engine = pxd.engine


pxd.vars.put("runtime.initMessage", "")
pxd.vars.setFlags("runtime", VARS_DONT_SAVE)


proc reportAppInitialized(api: DebugAPI) =
  let p1 = pxd.vars.get("runtime.initMessage",string)[]
  api.info &"Application initialized sucessfully!{p1}"


proc load*(api: VarsAPI, relativePath: string) =
  let path = pxd.io.path(relativePath)
  if fileExists(path):
    pxd.pods.fromPodFile(path, pxd.vars.source)
  else:
    pxd.pods.toPodFile(path, pxd.vars.source, PodSettings(style: PodStyle.Sparse))


proc save*(api: VarsAPI, relativePath: string) =
  let path =  pxd.io.path(relativePath)
  pxd.pods.toPodFile(path, pxd.vars.source, PodSettings(style: PodStyle.Sparse))


proc init(api: IoAPI) =
  pxd.vars.load("./assets/engine.pods")
  block init_folders:
    let developer = pxd.vars.source["app.developer"].vstring
    let title     = pxd.vars.source["app.title"].vstring
    let path      = &"{getDataDir()}/{developer}/{title}"
    pxd.io.app.dataPath = path
    if not dirExists(path):
      createDir(path)
  pxd.io.app.screen.w     = pxd.io.app.settings.window.w[]
  pxd.io.app.screen.h     = pxd.io.app.settings.window.h[]
  pxd.io.app.screen.ratio = float pxd.io.app.screen.w / pxd.io.app.screen.h


#------------------------------------------------------------------------------------------
# @api entry
#------------------------------------------------------------------------------------------
proc timestepBegin*(api: EngineAPI) {.inline.} =
  template trySnapDeltaTime(dt: var float, ms: float): untyped =
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
  io.init()
  pxd.render.init()
  engine.initAudio()
  p2d.initRenderer()
  pxd.debug.reportAppInitialized()


proc shutdown*(api: EngineAPI) {.inline.} =
  pxd.debug.shutdown()
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
      #todo: подумать нужно ли разделять на несколько кадров fixed
      template everyStep(apiStep: PxdAPI, codeStep: untyped) {.used.} =
        let ms = 1.0 / io.app.ups.float
        while ms <= timeState.stepLag:
          codeStep
          timeState.stepLag -= ms
          inc pxd.metrics.app.state.ticks
      while engine.shouldRun():
        pxd.platform.setVsync(io.app.settings.vsync[])
        engine.timestepBegin(); dt = timeState.delta
        pxd.platform.handleEvents(engine.onEvent, gameOnEvent)
        codeLoop
        engine.render()
        pxd.ecs.update()
        engine.timestepFinish()
        engine.measureFps()
  template loop(apiLoop: PxdAPI, codeLoop: untyped) {.dirty.} =
    loop(apiLoop, void, codeLoop)
  engine.init()
  code
  engine.shutdown()