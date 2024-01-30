import px_engine


# type GameAction = enum
#   Horizontal,
#   Vertical,
#   Interact


# pxd.run():
#   block init_input:
#     let input    = pxd.inputs.get()
#     let inputMap = pxd.inputs.getInputMap()
#     let inputCfg = pxd.inputs.getInputConfig()
#     inputCfg.digitalAxis.simulation  = true
#     inputCfg.digitalAxis.sensitivity = 3
#     inputCfg.digitalAxis.gravity     = 3
#     inputCfg.digitalAxis.snap        = false
#     inputCfg.digitalAxis.reverse     = true
#     inputMap.kbmAxis(Horizontal, Key.A, D)
#     inputMap.kbmAxis(Vertical, Key.S, W).invert()
#     inputMap.kbm(Interact, Key.Space)
#     input.bindMap(inputMap)
#     input.bindCfg(inputCfg)
#   let input = pxd.inputs.get()
#   pxd.loop():
#     if input.down(Interact):
#       print "interact"
#     if input.down(Key.Esc):
#       pxd.closeApp()
#     let axisx = input.axis(Horizontal)
#     let axisy = input.axis(Vertical)
#     pxd.everyStep():
#       print axisx, "::", axisy