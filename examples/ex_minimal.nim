import engine


proc onEvent(ev: EventId) =
  case ev:
    of EventWindowResize:
      print pxd.events.windowResize.height
    else:
      discard


pxd.run():
  pxd.loop(onEvent):
    discard