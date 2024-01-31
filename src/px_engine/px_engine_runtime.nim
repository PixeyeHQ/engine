import px_engine_pxd
import px_engine_vars
import px_engine_assets
import std/os
var
  frames = 0
  ticks  = 0
let
  engine = pxd.engine


#------------------------------------------------------------------------------------------
# @api timestep
#------------------------------------------------------------------------------------------
proc timestepBegin*(api: EngineAPI) {.inline.} =
  template trySnapDeltaTime(dt: var float, ms: float): untyped =
    ## Time snapping need to prevent sync issues and monitor stutternes without
    ## detecting vsync. We pretend that `deltatime` is always correct with fluctuations.
    if abs(dt-ms) < ms_fluctuation == true:
      dt = ms
  let timer = pxd.timer.state.addr
  let timeElapsed = timer.timeElapsed
  let time = pxd.timer.getTime(); timer.timeElapsed = time
  var dtUnscaled = time - timeElapsed
  trySnapDeltaTime(dtUnscaled, ms008)
  trySnapDeltaTime(dtUnscaled, ms016)
  trySnapDeltaTime(dtUnscaled, ms032)
  var dt = dtUnscaled * timer.scale
  # Prevent time anomalies.
  # If delta time is less than 0 it means system timer reseted.
  # If delta time is anormaly high, we don't want to fast forward the game in a step.
  timer.delta = clamp(dt, 0, msgap)
  timer.deltaUnscaled = clamp(dtUnscaled, 0, msgap)
  timer.stepLag += timer.delta
  # Prevent spiral of doom scenario.
  timer.stepLag = clamp(timer.stepLag, 0, msgap)

proc timestepFinish*(api: EngineAPI) =
  let timer = pxd.timer.state.addr
  inc timer.framesElapsed
  inc frames
  if pxd.vars.app_vsync: return
  let fps         = pxd.vars.app_fps; if fps < 0: return
  let ms = 1.0 / fps.float
  let dt = pxd.timer.getTime() - timer.timeElapsed
  if dt < ms:
    pxd.timer.sleep((ms-dt)*1000)

proc measureFps(api: EngineAPI) {.inline.} =
  pxd.timer.every(1.0, pm_seconds):
    pxd.vars.metrics_fps = frames
    pxd.vars.metrics_ups = ticks
    frames = 0
    ticks  = 0
  pxd.vars.metrics_drawcalls = pxd.vars.runtime_drawcalls
  pxd.vars.runtime_drawcalls = 0


#------------------------------------------------------------------------------------------
# @api entry private
#------------------------------------------------------------------------------------------
proc reportAppInitialized(api: DebugAPI) =
  let p1 = pxd.vars.get("runtime.initMessage", string)[]
  api.info &"Application initialized sucessfully!{p1}"




proc initVars(api: EngineAPI) = 
  pxd.vars.load("./engine.pods")
  block folders:
    let developer = pxd.vars.app_developer
    let title     = pxd.vars.app_title
    let path      = joinPath(getDataDir(),developer,title)
    pxd.vars.put("app.dataPath", path)
    if not dirExists(path):
      createDir(path)
  pxd.vars.runtime_screen_ratio = pxd.vars.app_screen_w / pxd.vars.app_screen_h




proc init*(api: EngineAPI) {.inline.} =
  pxd.engine.initVars()
  pxd.engine.initRender()
  pxd.engine.initRender2d()
  pxd.engine.initAudio()
  pxd.debug.reportAppInitialized()
  pxd.window.setVsync(pxd.vars.app_vsync)


proc shouldRun*(api: EngineAPI): bool {.inline.} =
  pxd.vars.app_wantsQuit == false


proc shutdown*(api: EngineAPI) {.inline.} =
  engine.shutdownAudio()
  pxd.debug.shutdown()


proc render(api: EngineAPI) {.inline.} =
  pxd.render.flush()
  pxd.engine.swapWindow()


proc update(api: EngineAPI) {.inline.} =
  pxd.ecs.update()


#------------------------------------------------------------------------------------------
# @api entry public
#------------------------------------------------------------------------------------------
proc closeApp*(api: PxdAPI) =
  api.vars.app_wantsQuit = true


proc update_system_debug_esc*() =
  if pxd.inputs.get.down Key.Esc: pxd.closeApp()


template run*(api: PxdAPI, code: untyped): untyped =
  #######
  let timer = pxd.timer.state.addr
  timer.delta = 1.0 / 60.0 # warmup
  template frame_begin*(apiStage: PxdAPI, codeStage: untyped) =
    codeStage
  template frame_end*(apiStage: PxdAPI, codeStage: untyped) =
    codeStage
  template update*(apiStage: PxdAPI, codeStage: untyped) =
    codeStage
  template update_end*(apiStage: PxdAPI, codeStage: untyped) =
    codeStage
  template update_begin*(apiStage: PxdAPI, codeStage: untyped) =
    codeStage
  template startup*(apiStage: PxdAPI, codeStage: untyped) =
    codeStage
  template draw*(apiDraw: PxdAPI, renderTexture: RenderTexture, codeDrawTexture: untyped) = 
    block:
      pxd.render.useFramebuffer(renderTexture.id)
      codeDrawTexture
      pxd.render.flush()
  template draw*(apiDraw: PxdAPI, codeDraw: untyped) = 
    block:
      pxd.render.useFramebuffer(0)
      codeDraw
  template loop(apiLoop: PxdAPI, procAppEvents: untyped, codeLoop: untyped) =
    var dt {.inject.}: float
    template everyStep(apiStep: PxdAPI, codeStep: untyped) {.used.} =
      let ms = 1 / pxd.vars.app_ups
      timer.delta = ms
      while ms <= timer.stepLag:
        codeStep
        timer.stepLag -= ms
        ticks         += 1
      timer.delta = dt
    while engine.shouldRun():
      timer.deltaFixed = 1 / pxd.vars.app_ups
      engine.timestepBegin(); dt = timer.delta
      pxd.platform.handleEvents(procAppEvents)
      codeLoop
      engine.update()
      engine.render()
      engine.timestepFinish()
      engine.measureFps()
  template loop*(apiLoop: PxdAPI, codeLoop: untyped) {.dirty.} =
    loop(apiLoop, void, codeLoop)
  #######
  engine.init()
  code
  engine.render()
  engine.shutdown()
