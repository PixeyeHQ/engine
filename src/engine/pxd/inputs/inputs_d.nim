import engine/pxd/platform/platform_d


type InputKind* {.pure, size: int32.sizeof.} = enum
  Keyboard,
  Gamepad


type InputAction* = object
  isCombo*:    bool
  isInverted*: bool
  pressed*:    bool
  pressedUp*:  bool        # check press when input UP.
  keysPositive*: seq[int]
  keysNegative*: seq[int]
  tempAxis*: float # ?


type DigitalAxisConfig* = object
  # 1) When input is received in the opposite direction of the current flow,snap axis value to 0 and continue from there.
  simulation*:  bool
  sensitivity*: float
  gravity*:     float
  snap*:        bool
  # When input is received in the opposite direction of the current flow,reverse the current value to the opposite sign and continue from there.
  reverse*:     bool


type InputConfig* = object
  tag*:         string
  digitalAxis*: DigitalAxisConfig
  deadZone*:    float


type InputMap* = object
  tag*:      string
  keyboard*: seq[InputAction]
  gamepad*:  seq[InputAction]


type Input* = object
  tag*: string
  map*: ptr InputMap
  cfg*: ptr InputConfig


type EventInputObj* = object
  mouseX*:       int32
  mouseY*:       int32
  keyState*:     array[SCANCODES_ALL.int, float]
  keyStateUp*:   array[SCANCODES_ALL.int, int]
  keyStateDown*: array[SCANCODES_ALL.int, int]