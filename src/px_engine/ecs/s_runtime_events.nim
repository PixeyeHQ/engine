import px_engine/m_pxd


const EventEngine = EventId.Next(EVENT_ID_ENGINE)
type EventObj_WindowResize = object
  width*:  int
  height*: int
type EventObj_Mouse = object


pxd.genEventAPI(EventWindowResize, EventObj_WindowResize, windowResize)
pxd.genEventAPI(EventMouse, EventObj_Mouse, mouse)


let io = pxd.io
#------------------------------------------------------------------------------------------
# @api events
#------------------------------------------------------------------------------------------
proc onEvent*(api: EngineAPI, ev: EventId) {.inline.} =
  case ev:
    of EventWindowResize:
      io.app.screen.w = pxd.events.windowResize.width
      io.app.screen.h = pxd.events.windowResize.height
      io.app.screen.ratio = float io.app.screen.w / io.app.screen.h
      pxd.vars.put("app.vars.screen.w", pxd.events.windowResize.width)
      pxd.vars.put("app.vars.screen.h", pxd.events.windowResize.height)
      pxd.vars.put("app.vars.screen.ratio", io.app.screen.ratio)
    else:
      discard