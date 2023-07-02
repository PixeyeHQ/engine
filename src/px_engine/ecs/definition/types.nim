import px_engine/pxd/definition/internal

type #@Input
  InputKind* {.pure, size: int32.sizeof.} = enum
    Keyboard,
    Gamepad


  InputAction* = object
    isCombo*:    bool
    isInverted*: bool
    pressed*:    bool
    pressedUp*:  bool        # check press when input UP.
    keysPositive*: seq[int]
    keysNegative*: seq[int]
    tempAxis*: float # ?


  DigitalAxisConfig* = object
    # 1) When input is received in the opposite direction of the current flow,snap axis value to 0 and continue from there.
    simulation*:  bool
    sensitivity*: float
    gravity*:     float
    snap*:        bool
    # When input is received in the opposite direction of the current flow,reverse the current value to the opposite sign and continue from there.
    reverse*:     bool


  InputConfig* = object
    tag*:         string
    digitalAxis*: DigitalAxisConfig
    deadZone*:    float


  InputMap* = object
    tag*:      string
    keyboard*: seq[InputAction]
    gamepad*:  seq[InputAction]


  Input* = object
    tag*: string
    map*: ptr InputMap
    cfg*: ptr InputConfig


  EventInputObj* = object
    mouseX*:       int32
    mouseY*:       int32
    keyState*:     array[SCANCODES_ALL.int, float]
    keyStateUp*:   array[SCANCODES_ALL.int, int]
    keyStateDown*: array[SCANCODES_ALL.int, int]


type #@Collisions
  CircleShape* = object
    position*: Vec2
    radius*: f32
  RectShape* = object
    position*: Vec2
    radius*:   Vec2
  PolygonShape* = object
    localVerts*: seq[Vec2] # local coords
    worldVerts*: seq[Vec2] # world coords
    bound*:    Vec2
    pivot*:    Vec2
    position*: Vec2
    rotation*: f32
  PolygonShapeBuilder* = object
    resultObject*: PolygonShape


type
  ProjectionKind* = enum
    Perspective,
    Orthographic

  CameraDef* = object
    projection*: ProjectionKind
    orthosize*:  float
    fov*:        float
    planeNear*:  float
    planeFar*:   float
    viewportKind*: int
    zoom*:         float


  ComponentCamera* = object
    matrixView*: Matrix
    matrixProj*: Matrix
    matrixViewInversed*: Matrix
    matrixProjInversed*: Matrix
    projection*: ProjectionKind
    zoom*:         float
    orthosize*:    float
    fov*:          float
    planeNear*:    float
    planeFar*:     float
    aspectRatio*:  float
    viewportKind*: int

type
  ComponentTransform* = object
    qrotation*: Quat
    rotation*:  Vec3
    position*:  Vec3
    scale*:     Vec3


  ComponentObject* = object
    parent*: Ent
    childs*: seq[Ent]
  

  ComponentSprite* = object
    color*:  Color
    height*: float
    data*:   Sprite


  ComponentInteraction* = object
    rect*: RectShape
    onClick*: proc()


type #@Entities
  Object* = distinct Ent
  Camera* = distinct Ent


converter toEnt*(self: Object): Ent     = self.Ent
converter toObj*(self: Camera): Object = self.Object
converter toEnt*(self: Camera): Ent    = self.Ent