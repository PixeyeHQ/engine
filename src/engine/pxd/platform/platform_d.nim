when defined(sdl):
  import vendor/sdl

  const SCANCODES_MOUSE_BEGIN*     = 350
  const SCANCODES_MOUSE_END*       = 366
  const SCANCODES_MOUSE*           = SCANCODES_MOUSE_END - SCANCODES_MOUSE_BEGIN
  const SCANCODES_ALL*             = 512
  type Key* {.pure, size: int32.sizeof.} = enum # sdl layout + mouse
    Unknown    = SCANCODE_UNKNOWN
    A          = SCANCODE_A
    B          = SCANCODE_B
    C          = SCANCODE_C
    D          = SCANCODE_D
    E          = SCANCODE_E
    F          = SCANCODE_F
    G          = SCANCODE_G
    H          = SCANCODE_H
    I          = SCANCODE_I
    J          = SCANCODE_J
    K          = SCANCODE_K
    L          = SCANCODE_L
    M          = SCANCODE_M
    N          = SCANCODE_N
    O          = SCANCODE_O
    P          = SCANCODE_P
    Q          = SCANCODE_Q
    R          = SCANCODE_R
    S          = SCANCODE_S
    T          = SCANCODE_T
    U          = SCANCODE_U
    V          = SCANCODE_V
    W          = SCANCODE_W
    X          = SCANCODE_X
    Y          = SCANCODE_Y
    Z          = SCANCODE_Z
    K1         = SCANCODE_1
    K2         = SCANCODE_2
    K3         = SCANCODE_3
    K4         = SCANCODE_4
    K5         = SCANCODE_5
    K6         = SCANCODE_6
    K7         = SCANCODE_7
    K8         = SCANCODE_8
    K9         = SCANCODE_9
    K0         = SCANCODE_0
    Enter      = SCANCODE_RETURN
    Esc        = SCANCODE_ESCAPE
    Backspace  = SCANCODE_BACKSPACE
    Tab        = SCANCODE_TAB
    Space      = SCANCODE_SPACE
    Minus      = SCANCODE_MINUS
    Equal      = SCANCODE_EQUALS
    LeftBracket  = SCANCODE_LEFTBRACKET
    RightBracket = SCANCODE_RIGHTBRACKET
    Backslash    = SCANCODE_BACKSLASH
    Semilicon    = SCANCODE_SEMICOLON
    Apostrophe   = SCANCODE_APOSTROPHE
    Tilde        = SCANCODE_GRAVE
    Comma        = SCANCODE_COMMA
    Period       = SCANCODE_PERIOD
    Slash        = SCANCODE_SLASH
    CapsLock     = SCANCODE_CAPSLOCK
    F1           = SCANCODE_F1
    F2           = SCANCODE_F2
    F3           = SCANCODE_F3
    F4           = SCANCODE_F4
    F5           = SCANCODE_F5
    F6           = SCANCODE_F6
    F7           = SCANCODE_F7
    F8           = SCANCODE_F8
    F9           = SCANCODE_F9
    F10          = SCANCODE_F10
    F11          = SCANCODE_F11
    F12          = SCANCODE_F12
    PrintScreen  = SCANCODE_PRINTSCREEN
    ScrollLock   = SCANCODE_SCROLLLOCK
    Pause        = SCANCODE_PAUSE
    Insert       = SCANCODE_INSERT
    Home         = SCANCODE_HOME
    PageUp       = SCANCODE_PAGEUP
    Delete       = SCANCODE_DELETE
    End          = SCANCODE_END
    PageDown     = SCANCODE_PAGEDOWN
    Right        = SCANCODE_RIGHT
    Left         = SCANCODE_LEFT
    Down         = SCANCODE_DOWN
    Up           = SCANCODE_UP
    Numlock      = SCANCODE_NUMLOCKCLEAR
    KpDivide     = SCANCODE_KP_DIVIDE
    KpMultiply   = SCANCODE_KP_Multiply
    KpEnter      = SCANCODE_KP_ENTER
    Kp1          = SCANCODE_KP_1
    Kp2          = SCANCODE_KP_2
    Kp3          = SCANCODE_KP_3
    Kp4          = SCANCODE_KP_4
    Kp5          = SCANCODE_KP_5
    Kp6          = SCANCODE_KP_6
    Kp7          = SCANCODE_KP_7
    Kp8          = SCANCODE_KP_8
    Kp9          = SCANCODE_KP_9
    Kp0          = SCANCODE_KP_0
    KpEqual      = SCANCODE_KP_EQUALS
    F13          = SCANCODE_F13
    F14          = SCANCODE_F14
    F15          = SCANCODE_F15
    F16          = SCANCODE_F16
    F17          = SCANCODE_F17
    F18          = SCANCODE_F18
    F19          = SCANCODE_F19
    F20          = SCANCODE_F20
    F21          = SCANCODE_F21
    F22          = SCANCODE_F22
    F23          = SCANCODE_F23
    F24          = SCANCODE_F24
    Menu         = SCANCODE_MENU
    KpAdd        = SCANCODE_KP_MEMADD
    KpSubstract  = SCANCODE_KP_MEMSUBTRACT
    KpDecimal    = SCANCODE_KP_DECIMAL
    LeftCtrl     = SCANCODE_LCTRL
    LeftShift    = SCANCODE_LSHIFT
    LeftAlt      = SCANCODE_LALT
    RightCtrl    = SCANCODE_RCTRL
    RightShift   = SCANCODE_RSHIFT
    RightAlt     = SCANCODE_RALT
    NumMouseBegin = SCANCODES_MOUSE_BEGIN
    MLeft         = 351
    MMiddle       = 352
    MRight        = 353
    MButton4      = 354
    MButton5      = 355
    MButton6      = 356
    MButton7      = 357
    NumMouseEnd   = SCANCODES_MOUSE_END
    NumScancodes  = SCANCODES_ALL

  
  type EventIo* = object
    mouseX*: int32
    mouseY*: int32
    keyState*: array[SCANCODES_ALL.int, float]
    keyStateUp*: array[SCANCODES_ALL.int, int]
    keyStateDown*: array[SCANCODES_ALL.int, int]

