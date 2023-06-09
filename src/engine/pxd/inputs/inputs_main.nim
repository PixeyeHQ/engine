import std/tables
import engine/px
import pxd/api
import pxd/m_debug
import pxd/m_time
import pxd/m_utils
import pxd/platform/platform_d
import inputs_d
import inputs_event


type InputState = object
  source: Table[string, Input]
  maps:   Table[string, InputMap]
  cfgs:   Table[string, InputConfig]


var input_state = InputState()
input_state.source = initTable[string, Input]()
input_state.maps   = initTable[string, InputMap]()
input_state.cfgs   = initTable[string, InputConfig]()


proc state*(api: InputAPI): var InputState =
  input_state


proc get*(api: InputAPI, tag: string): ptr Input =
  if input_state.source.hasKey(tag):
    return input_state.source[tag].addr
  else:
    input_state.source[tag] = Input(tag: tag)
    return input_state.source[tag].addr


proc get*(api: InputAPI): ptr Input =
  result = api.get("system")


proc getInputMap*(api: InputAPI, tag: string): ptr InputMap =
  if input_state.maps.hasKey(tag):
    return input_state.maps[tag].addr
  else:
    input_state.maps[tag] = InputMap(tag: tag)
    return input_state.maps[tag].addr


proc getInputMap*(api: InputAPI): ptr InputMap =
  result = api.getInputMap("default")


proc getInputConfig*(api: InputAPI, tag: string): ptr InputConfig =
  if input_state.cfgs.haskey(tag):
    return input_state.cfgs[tag].addr
  else:
    input_state.cfgs[tag] = InputConfig(tag: tag)
    return input_state.cfgs[tag].addr


proc getInputConfig*(api: InputAPI): ptr InputConfig =
  result = api.getInputConfig("default")


type InputBuilder = object
  input:  ptr InputMap
  action: ptr InputAction
type ChainInputAxis = object of MethodChain[InputBuilder]


const NEGATIVE = false
const POSITIVE = true


var keyState     = pxd.events.input.keyState.addr
var keyStateUp   = pxd.events.input.keyStateUp.addr
var keyStateDown = pxd.events.input.keyStateDown.addr


using
  input: var Input | ptr Input
  inputMap: var InputMap | ptr InputMap


proc getAction(inputMap; actionId: int, kind: InputKind): ptr InputAction


proc get(input; key: int): bool =
  result = keyState[key] > 0.0


proc down(input; key: int): bool =
  result = keyStateDown[key] > 0


proc up(input; key: int): bool =
  result = keyStateUp[key] > 0


proc downAny(input; keys: ptr seq[int]): bool {.inline.} =
  for k in keys[]:
    if down(input, k):
      result = true
      break


proc upAny(input; keys: ptr seq[int]): bool {.inline.} =
  for k in keys[]:
    if up(input, k):
      result = true
      break


proc get*(input; key: Key): bool =
  get(input, key.ord)


proc down*(input; key: Key): bool =
  down(input, key.ord)


proc up*(input; key: Key): bool = 
  up(input, key.ord)


proc getAll(input; keys: ptr seq[int]): bool {.inline.} =
  for k in keys[]:
    if not get(input, k.ord):
      return false
  result = true


proc getAny(input; keys: ptr seq[int]): bool {.inline.} =
  for k in keys[]:
    if get(input, k):
      result = true
      break


proc getAction(input; key: enum): ptr InputAction =
  let keycode = key.ord
  let map     = input.map
  if map.keyboard.len > keycode:
    result = map.keyboard[keycode].addr
  else:
    result = nil


proc getAction(inputMap; actionId: int, kind: InputKind): ptr InputAction =
  case kind:
    of Keyboard:
      return inputMap.keyboard.getPtr(actionId)
    of GamePad:
      discard


proc getKeys(action: ptr InputAction, isKeyPositive: bool): ptr seq[int] =
  let keyDirection = isKeyPositive != action.isInverted
  result =
    if keyDirection == POSITIVE:
      action.keysPositive.addr
    else:
      action.keysNegative.addr


proc getAxis(input: ptr Input, action: ptr InputAction): float =
  if getAny(input, action.keysPositive.addr):
    result += 1
  if getAny(input, action.keysNegative.addr):
    result -= 1
  if action.isInverted:
    result = -result


proc axis*(input: ptr Input, key: not Key and enum): float =
  let action       = `?f` input.getAction(key)
  let sensitivity  = input.cfg.digitalAxis.sensitivity
  let gravity      = input.cfg.digitalAxis.gravity
  let inSimulation = input.cfg.digitalAxis.simulation
  let axis         = input.getAxis(action)
  let time         = pxd.time.state.addr
 #
  template handleSnapGravity() =
    const gap_step = 0.5f
    if abs(action.tempAxis) <= gravity * time.delta * gap_step:
      action.tempAxis = 0
  proc handleSnap() =
    if not input.cfg.digitalAxis.snap:
      return
    if action.tempAxis > 0 and axis == -1:  action.tempAxis = 0
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
      if action.tempAxis > 0:   action.tempAxis -= gravity * time.delta
      elif action.tempAxis < 0: action.tempAxis += gravity * time.delta
    action.tempAxis = clamp(action.tempAxis, -1, 1)
    handleSnapGravity()
    result = action.tempAxis
  else:
    result = axis


proc get(input; action: ptr InputAction, isKeyPositive: bool): bool =
  let keys = action.getKeys(isKeyPositive)
  if action.isCombo:
    result = getAll(input, keys)
  else:
    result = getAny(input, keys)


proc down(input; action: ptr InputAction, isKeyPositive: bool): bool =
  let keys = action.getKeys(isKeyPositive)
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


proc up(input: ptr Input, action: ptr InputAction, isKeyPositive: bool): bool =
  let keys = action.getKeys(isKeyPositive)
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


proc bindMap*(input; map: ptr InputMap) =
  input.map = map


proc bindCfg*(input; cfg: ptr InputConfig) =
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


proc kbmAxis*[T: enum](self: ptr InputMap, action: enum, keys: varargs[T]): ChainInputAxis {.discardable.} =
  proc debugProps(keys: varargs[T]) =
    if (keys.len and 1) != 0:
      debug.fatal("Input", "You need both positive and negative keys.")
  debugProps(keys)
  let action = self.getAction(ord(action), InputKind.Keyboard)
  for keyIndex in countup(0, keys.high, 2):
    action.keysNegative.add(ord(keys[keyIndex]))
    action.keysPositive.add(ord(keys[keyIndex + 1]))
  result.state.action = action
  result.state.input  = self


proc invert*(self: ChainInputAxis) =
  self.state.action.isInverted = true