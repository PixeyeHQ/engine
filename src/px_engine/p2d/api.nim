import ../pxd/api
type
  P2DrawAPI* = distinct API_Obj
  P2DAudioAPI* = distinct API_Obj
  P2DPhysicsAPI* = distinct API_Obj
var
  api_p2d_draw = P2DrawAPI(api_o)
  api_p2d_audio = P2DAudioAPI(api_o)
  api_p2d_physics = P2DPhysicsAPI(api_o)
var
  p2d* = P2D_API(api_o) ## API: Core engine stuff

proc draw*(self: P2D_API): P2DrawAPI = api_p2d_draw
proc audio*(self: P2D_API): P2DAudioAPI = api_p2d_audio
proc physics*(self: P2D_API): P2DPhysicsAPI = api_p2d_physics