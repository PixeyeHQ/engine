type 
  API_Obj*      = object
  PxdAPI*       = distinct API_Obj
  DebugAPI*     = distinct API_Obj
  VarsAPI*      = distinct API_Obj
  IoAPI*        = distinct API_Obj
  PodsAPI*      = distinct API_Obj
  EcsAPI*       = distinct API_Obj
  EngineAPI*    = distinct API_Obj
  EventAPI*     = distinct API_Obj
  RenderAPI*    = distinct API_Obj
  PlatformAPI*  = distinct API_Obj
  InputAPI*     = distinct API_Obj
  TimeAPI*      = distinct API_Obj
  ResAPI*       = distinct API_Obj
  MetricsAPI*   = distinct API_Obj
  Commands*     = distinct API_Obj
  P2DAPI*       = distinct API_Obj
  P2DrawAPI*    = distinct API_Obj
  P2DAudioAPI*  = distinct API_Obj
  PxdCreateAPI* = distinct API_Obj
  P2dCreateAPI* = distinct API_Obj
  P2dPhysicsAPI* = distinct API_Obj

type
  RenderAPI_Internal* = distinct API_Obj


var # inner handles
  api_o*              = API_Obj()
  pods_api            = PodsAPI(api_o)
  pxd_create_api      = PxdCreateAPI(api_o)
  p2d_create_api      = P2dCreateAPI(api_o)
  vars_api            = VarsAPI(api_o)
  ecs_api             = EcsAPI(api_o)
  event_api           = EventAPI(api_o)
  render_api          = RenderAPI(api_o)
  platform_api        = PlatformAPI(api_o)
  input_api           = InputAPI(api_o)
  time_api            = TimeAPI(api_o)
  res_api             = ResAPI(api_o)
  render_api_internal = RenderAPI_Internal(api_o)
  metrics_api         = MetricsAPI(api_o)
  io_api              = IoAPI(api_o) 
  debug_api           = DebugAPI(api_o)
  engine_api          = EngineAPI(api_o)
  p2draw_api          = P2DrawAPI(api_o)
  p2daudio_api        = P2DAudioAPI(api_o)
  p2dphysics_api      = P2dPhysicsAPI(api_o)

var # main handles
  pxd*     = PxdAPI(api_o)  ## API: Core engine stuff
  p2d*     = P2dAPI(api_o)  ## API: Engine 2D Renderer, Physics and Audio

proc draw*(api: P2dAPI): P2DrawAPI =
  p2draw_api


proc audio*(api: P2dAPI): P2DAudioAPI =
  p2daudio_api


proc create*(api: P2dAPI): P2dCreateAPI =
  ## Handle for making/getting entities.
  p2d_create_api


proc physics*(api: P2dAPI): P2dPhysicsAPI =
  ## Handle for 2d physics
  p2dphysics_api

#------------------------------------------------------------------------------------------
# @api pxd
#------------------------------------------------------------------------------------------
{.push inline.}


proc pods*(api: PxdAPI): PodsAPI =
  pods_api


proc create*(api: PxdAPI): PxdCreateAPI =
  ## Handle for making/getting entities.
  pxd_create_api


proc ecs*(api: PxdAPI): EcsAPI =
  ecs_api


proc render*(api: PxdAPI): RenderAPI =
  render_api


proc platform*(api: PxdAPI): PlatformAPI =
  platform_api


proc inputs*(api: PxdAPI): InputAPI =
  input_api


proc time*(api: PxdAPI): TimeAPI =
  time_api


proc metrics*(api: PxdAPI): MetricsAPI =
  metrics_api


proc res*(api: PxdAPI): ResAPI =
  ## Handle assets of the app.
  res_api


proc events*(api: PxdAPI): EventAPI =
  event_api


proc io*(api: PxdAPI): IoAPI =
  ## API: Input/Output of the engine
  io_api


proc debug*(api: PxdAPI): DebugAPI =
  ## API: Debug commands
  debug_api


proc engine*(api: PxdAPI): EngineAPI =
  ## API: Internal Engine
  engine_api 


proc vars*(api: PxdAPI): VarsAPI =
  ## Handle vars.
  vars_api

{.pop.}

import types
export types


template genEventAPI*(hook: PxdAPI, event: untyped, typeObjId: untyped, procId: untyped)=
  var eventObj: typeObjId
  
  const event* {.inject.} = EventId.Next

  proc procId*(api: EventAPI): var typeObjId {.inject, inline.} =
    eventObj
  
  proc eventId*(self: var typeObjId): EventId {.inject, inline.} =
    event
template genEventAPI*(hook: PxdAPI, event: untyped) {.dirty.} =
  const event* {.inject.} = EventId.Next

