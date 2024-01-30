import px_pods
import ../px_engine_types
export px_engine_types
type
  PxdAPI* = distinct API_Obj
  EventAPI* = distinct API_Obj
  DebugAPI* = distinct API_Obj
  VarsAPI* = distinct API_Obj
  InputAPI* = distinct API_Obj
  TimerAPI* = distinct API_Obj
  PlatformAPI* = distinct API_Obj
  RenderAPI* = distinct API_Obj
  Render2dAPI* = distinct API_Obj
  EngineAPI* = distinct API_Obj
  CommandsAPI* = distinct API_Obj
  FileSystemAPI* = distinct API_Obj
  WindowAPI* = distinct API_Obj
  MathAPI* = distinct API_Obj
  AssetAPI* = distinct API_Obj
  RenderAPI_Private* = distinct API_Obj
  MemoryAPI* = distinct API_Obj
  P2dAPI* = distinct API_Obj
  IndexAPI*      = distinct API_Obj
  EcsAPI*        = distinct API_Obj
  CreateAPI*     = distinct API_Obj
const
  VARS_DONT_SAVE* = POD_DONT_SAVE
var
  api_debug = DebugAPI(api_o)
  api_vars = VarsAPI(api_o)
  api_input = InputAPI(api_o)
  api_event = EventAPI(api_o)
  api_timer = TimerAPI(api_o)
  api_platform = PlatformAPI(api_o)
  api_render = RenderAPI(api_o)
  api_engine = EngineAPI(api_o)
  api_filesystem = FileSystemAPI(api_o)
  api_commands = CommandsAPI(api_o)
  api_window = WindowAPI(api_o)
  api_math = MathAPI(api_o)
  api_render_private = RenderAPI_Private(api_o)
  api_asset    = AssetAPI(api_o)
  api_memory   = MemoryAPI(api_o)
  api_ecs      = EcsAPI(api_o)
  api_create   = CreateAPI(api_o)
var
  pxd* = PxdAPI(api_o) ## API: Core engine stuff
proc debug*(self: PxdAPI): DebugAPI = api_debug
proc vars*(self: PxdAPI): VarsAPI = api_vars
proc cmds*(self: PxdAPI): CommandsAPI = api_commands
proc inputs*(self: PxdAPI): InputAPI = api_input
proc assets*(self: PxdAPI): AssetAPI = api_asset
proc events*(self: PxdAPI): EventAPI = api_event
proc timer*(self: PxdAPI): TimerAPI = api_timer
proc platform*(self: PxdAPI): PlatformAPI = api_platform
proc render*(self: PxdAPI): RenderAPI = api_render
proc engine*(self: PxdAPI): EngineAPI = api_engine
proc filesystem*(self: PxdAPI): FileSystemAPI = api_filesystem
proc window*(self: PxdAPI): WindowAPI = api_window
proc math*(self: PxdAPI): MathAPI = api_math
proc memory*(self: PxdAPI): MemoryAPI = api_memory
proc private*(self: RenderAPI): RenderAPI_Private = api_render_private
proc ecs*(self: PxdAPI): EcsAPI = api_ecs
proc create*(self: PxdAPI): CreateAPI = api_create



