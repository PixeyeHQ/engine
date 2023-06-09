type 
  API_Obj*     = object
  PxdAPI*      = distinct API_Obj
  DebugAPI*    = distinct API_Obj
  EntsAPI*     = distinct API_Obj
  VarsAPI*     = distinct API_Obj
  IoAPI*       = distinct API_Obj
  PodsAPI*     = distinct API_Obj
  EcsAPI*      = distinct API_Obj
  EngineAPI*   = distinct API_Obj
  EventAPI*    = distinct API_Obj
  RenderAPI*   = distinct API_Obj
  PlatformAPI* = distinct API_Obj
  InputAPI*    = distinct API_Obj
  TimeAPI*     = distinct API_Obj
  ResAPI*      = distinct API_Obj
  MetricsAPI*  = distinct API_Obj
  Commands*    = distinct API_Obj
type
  RenderAPI_Internal* = distinct API_Obj


var # inner handles
  api_o*        = API_Obj()
  pods_api      = PodsAPI(api_o)
  ents_api      = EntsAPI(api_o)
  vars_api      = VarsAPI(api_o)
  ecs_api       = EcsAPI(api_o)
  event_api     = EventAPI(api_o)
  render_api    = RenderAPI(api_o)
  platform_api  = PlatformAPI(api_o)
  input_api     = InputAPI(api_o)
  time_api      = TimeAPI(api_o)
  res_api       = ResAPI(api_o)
  render_api_internal = RenderAPI_Internal(api_o)
  metrics_api   = MetricsAPI(api_o)


var # main handles
  io*      = IoAPI(api_o)     ## API: Input/Output of the engine
  pxd*     = PxdAPI(api_o)    ## API: Core engine stuff
  debug*   = DebugAPI(api_o)  ## API: Debug commands
  engine*  = EngineAPI(api_o) ## API: Internal Engine

#------------------------------------------------------------------------------------------
# @api pxd
#------------------------------------------------------------------------------------------
{.push inline.}


proc pods*(api: PxdAPI): PodsAPI =
  pods_api


proc ents*(api: PxdAPI): EntsAPI =
  ## Handle for making/getting entities.
  ents_api


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


#------------------------------------------------------------------------------------------
# @api io
#------------------------------------------------------------------------------------------
proc vars*(api: IoAPI): VarsAPI =
  ## Handle vars.
  vars_api


{.pop.}


import m_pxd_d
export m_pxd_d