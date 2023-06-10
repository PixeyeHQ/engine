import engine


proc onEvent(ev: EventId) =
  case ev:
    of EventWindowResize:
      print pxd.events.windowResize.height
    else:
      discard


pxd.run():
  let input = pxd.inputs.get()
  pxd.loop(onEvent):
    if input.down(Key.Esc):
      pxd.closeApp()
    discard