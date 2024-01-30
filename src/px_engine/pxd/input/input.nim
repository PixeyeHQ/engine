import std/tables
import ../platform/platform_d
import ../api
import ../m_math
import ../m_event
import ../m_vars
import ../m_renderer
import ../../px_engine_toolbox
import input_d


type
  InputState = object
    items: Table[string, Input]
    maps: Table[string, InputMap]
    cfgs: Table[string, InputConfig]
  InputBuilder = object
    input: InputMap
    action: InputAction
  ChainInputAxis = object of MethodChain[InputBuilder]
const
  NEGATIVE = false
  POSITIVE = true
var
  inputState = InputState()


pxd.events.gen(EventInput, EventInputObj, input)


inputState.items = initTable[string, Input]()
inputState.maps  = initTable[string, InputMap]()
inputState.cfgs  = initTable[string, InputConfig]()


proc get*(api: InputAPI, tag: string): Input =
  if not inputState.items.hasKey(tag):
    inputState.items[tag] = Input(tag: tag)
  inputState.items[tag]
proc get*(api: InputAPI): Input =
  result = api.get("system")


proc getMap*(api: InputAPI, tag: string): InputMap =
  if not inputState.maps.hasKey(tag):
    inputState.maps[tag] = InputMap(tag: tag)
  inputState.maps[tag]
proc getMap*(api: InputAPI): InputMap =
  result = api.getMap("default")


proc getConfig*(api: InputAPI, tag: string): InputConfig =
  if not inputState.cfgs.haskey(tag):
    inputState.cfgs[tag] = InputConfig(tag: tag)
  inputState.cfgs[tag]
proc getConfig*(api: InputAPI): InputConfig =
  result = api.getConfig("default")


let keyState     = pxd.events.input.keyState.addr
let keyStateUp   = pxd.events.input.keyStateUp.addr
let keyStateDown = pxd.events.input.keyStateDown.addr


using
  input: Input
  inputMap: InputMap


proc getAction(inputMap; actionId: int, kind: InputKind): InputAction


proc get(input; key: int): bool =
  result = keyState[key] > 0.0


proc down(input; key: int): bool =
  result = keyStateDown[key] > 0


proc up(input; key: int): bool =
  result = keyStateUp[key] > 0


proc downAny(input; keys: var seq[int]): bool {.inline.} =
  for k in keys:
    if down(input, k):
      result = true
      break


proc upAny(input; keys: var seq[int]): bool {.inline.} =
  for k in keys:
    if up(input, k):
      result = true
      break


proc get*(input; key: Key): bool =
  get(input, key.ord)


proc down*(input; key: Key): bool =
  down(input, key.ord)


proc up*(input; key: Key): bool =
  up(input, key.ord)


proc getAll(input; keys: var seq[int]): bool {.inline.} =
  for k in keys:
    if not get(input, k.ord):
      return false
  result = true


proc getAny(input; keys: var seq[int]): bool {.inline.} =
  for k in keys:
    if get(input, k):
      result = true
      break


proc getAction(input; key: enum): InputAction =
  let keycode = key.ord
  let map = input.map
  if map.keyboard.len > keycode:
    result = map.keyboard[keycode]
  else:
    result = nil


proc getAction(inputMap; actionId: int, kind: InputKind): InputAction =
  case kind:
    of Keyboard:
      var a = inputMap.keyboard.get(actionId)
      return a
    of GamePad:
      discard


proc getKeys(action: InputAction, isKeyPositive: bool): seq[int] =
  let keyDirection = isKeyPositive != action.isInverted
  result =
    if keyDirection == POSITIVE:
      action.keysPositive
    else:
      action.keysNegative


proc getAxis(input: Input, action: InputAction): float =
  if getAny(input, action.keysPositive):
    result += 1
  if getAny(input, action.keysNegative):
    result -= 1
  if action.isInverted:
    result = -result


proc axis*(input: Input, key: not Key and enum): float =
  let action = `?f`input.getAction(key)
  let sensitivity = input.cfg.digitalAxis.sensitivity
  let gravity = input.cfg.digitalAxis.gravity
  let inSimulation = input.cfg.digitalAxis.simulation
  let axis = input.getAxis(action)
  let time = pxd.timer.state.addr
#
  template handleSnapGravity() =
    const gap_step = 0.5f
    if abs(action.tempAxis) <= gravity * time.delta * gap_step:
      action.tempAxis = 0
  proc handleSnap() =
    if not input.cfg.digitalAxis.snap:
      return
    if action.tempAxis > 0 and axis == -1: action.tempAxis = 0
    elif action.tempAxis < 0 and axis == 1: action.tempAxis = 0
  proc handleReverse() =
    if not input.cfg.digitalAxis.reverse:
      return
    if (action.tempAxis > 0 and axis == -1) or (action.tempAxis < 0 and axis == 1):
      action.tempAxis *= -1
#
  if inSimulation:
    if axis != 0:
      handleSnap()
      handleReverse()
      action.tempAxis += axis * sensitivity * time.delta
    else:
      if action.tempAxis > 0: action.tempAxis -= gravity * time.delta
      elif action.tempAxis < 0: action.tempAxis += gravity * time.delta
    action.tempAxis = clamp(action.tempAxis, -1, 1)
    handleSnapGravity()
    result = action.tempAxis
  else:
    result = axis


proc get(input; action: InputAction, isKeyPositive: bool): bool =
  var keys = action.getKeys(isKeyPositive)
  if action.isCombo:
    result = getAll(input, keys)
  else:
    result = getAny(input, keys)


proc down(input; action: InputAction, isKeyPositive: bool): bool =
  var keys = action.getKeys(isKeyPositive)
  if action.isCombo:
    if not getAll(input, keys):
      action.pressed = false
      return false
    if action.pressed:
      return false
    action.pressed = true
    return true
  else:
    result = downAny(input, keys)


proc up(input: Input, action: InputAction, isKeyPositive: bool): bool =
  var keys = action.getKeys(isKeyPositive)
  if action.isCombo:
    if getAll(input, keys):
      action.pressedUp = true
      return false
    if action.pressedUp:
      if not getAll(input, keys):
        action.pressedUp = false
        return true
  else:
    result = upAny(input, keys)


proc get*[T: enum](input; key: T): bool =
  var action = ? getAction(input, key)
  get(input, action, POSITIVE)


proc getNegative*[T: not Key and enum](input: ptr Input, key: T): bool =
  let action = ? getAction(input, key)
  get(input, action, NEGATIVE)


proc down*[T: enum](input; key: T): bool =
  var action = ? getAction(input, key)
  down(input, action, POSITIVE)


proc downNegative*[T: not Key and enum](input: ptr Input, key: T): bool =
  let action = ? getAction(input, key)
  down(input, action, NEGATIVE)


proc up*[T: enum](input; key: T): bool =
  var action = ? getAction(input, key)
  up(input, action, POSITIVE)


proc upNegative*[T: not Key and enum](input: ptr Input, key: T): bool =
  let action = ? getAction(input, key)
  up(input, action, NEGATIVE)


proc bindMap*(input; map: InputMap) =
  input.map = map


proc bindCfg*(input; cfg: InputConfig) =
  input.cfg = cfg


proc kbm*[T: enum](inputMap; action: enum, keys: varargs[T]) =
  let action = inputMap.getAction(action.ord, InputKind.Keyboard)
  for key in keys:
    action.keysPositive.add(ord(key))


proc kbmCombo*[T: enum](inputMap; action: enum, keys: varargs[T]) =
  let action = inputMap.getAction(action.ord, InputKind.Keyboard)
  for key in keys:
    action.keysPositive.add(ord(key))
  action.isCombo = true


proc kbmAxis*[T: enum](inputMap; action: enum, keys: varargs[
    T]): ChainInputAxis {.discardable.} =
  proc debugProps(keys: varargs[T]) =
    if (keys.len and 1) != 0:
      #pxd.debug.fatal("Input", "You need both positive and negative keys.")
      discard
  debugProps(keys)
  var action = inputMap.getAction(ord(action), InputKind.Keyboard)
  for keyIndex in countup(0, keys.high, 2):
    action.keysNegative.add(ord(keys[keyIndex]))
    action.keysPositive.add(ord(keys[keyIndex + 1]))
  result.state.action = action
  result.state.input = inputMap


proc invert*(self: ChainInputAxis) =
  self.state.action.isInverted = true



let app_screen_w = pxd.vars.get("app.screen.w", int)
let app_screen_h = pxd.vars.get("app.screen.h", int)
let viewport_w = pxd.vars.get("runtime.viewport.w", float)
let viewport_h = pxd.vars.get("runtime.viewport.h", float)


proc mouseWorldPosition*(api: InputAPI): Vec3 =
  let mx  = pxd.vars.mouse.x
  let my  = pxd.vars.mouse.y
  # normalize
  let nmx = mx / viewport_w[].int
  let nmy = my / viewport_h[].int
  # normalize device coords
  let ndcx = (nmx*2)-1
  let ndcy = 1 - (nmy*2)
  # get final world position
  var matrixTransform = mul(inverse(pxd.render.frame.uproj), pxd.render.frame.uview)
  result = mul(matrixTransform, vec(ndcx,ndcy,0,1))
  result.z = 0



proc mousePosition*(api: InputAPI): Vec3 =
  result.x = pxd.vars.mouse.x.f32
  result.y = app_screen_h[].f32 - pxd.vars.mouse.y.f32
