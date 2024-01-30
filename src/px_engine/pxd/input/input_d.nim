import ../platform/platform_d
type #@Input
  InputKind* {.pure, size: int32.sizeof.} = enum
    Keyboard,
    Gamepad
  InputAction* = ref object
    isCombo*:    bool
    isInverted*: bool
    pressed*:    bool
    pressedUp*:  bool        # check press when input UP.
    keysPositive*: seq[int]
    keysNegative*: seq[int]
    tempAxis*: float # ?
  DigitalAxisParams* = object
    # 1) When input is received in the opposite direction of the current flow,snap axis value to 0 and continue from there.
    simulation*:  bool
    sensitivity*: float
    gravity*:     float
    snap*:        bool
    # When input is received in the opposite direction of the current flow,reverse the current value to the opposite sign and continue from there.
    reverse*:     bool
  InputConfig* = ref object
    tag*:         string
    digitalAxis*: DigitalAxisParams
    deadZone*:    float
  InputMap* = ref object
    tag*:      string
    keyboard*: seq[InputAction]
    gamepad*:  seq[InputAction]
  Input* = ref object
    tag*: string
    map*: InputMap
    cfg*: InputConfig
  EventInputObj* = object
    keyState*:     array[SCANCODES_ALL.int, float]
    keyStateUp*:   array[SCANCODES_ALL.int, int]
    keyStateDown*: array[SCANCODES_ALL.int, int]