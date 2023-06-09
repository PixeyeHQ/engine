import engine/pxd/api


type
  P2D_API*     = distinct API_Obj
  P2DrawAPI*   = distinct API_Obj
  P2DAudioAPI* = distinct API_Obj
var # inner handles
  api_o = API_Obj()
var
  p2d*     = P2dAPI(api_o)     ## API: Engine 2D Renderer, Physics and Audio
  p2draw   = P2DrawAPI(api_o)
  p2daudio = P2DAudioAPI(api_o)


proc draw*(api: P2dAPI): P2DrawAPI =
  p2draw


proc audio*(api: P2dAPI): P2DAudioAPI =
  p2daudio