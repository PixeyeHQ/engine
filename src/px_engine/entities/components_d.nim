import px_engine/pxd/m_math
import px_engine/pxd/m_ecs
import px_engine/p2d/p2d_d
import px_engine/assets/asset_sprite


type
  ProjectionKind* = enum
    Perspective,
    Orthographic


  ConfigCamera* = object
    projection*: ProjectionKind
    orthosize*:  float
    fov*:        float
    planeNear*:  float
    planeFar*:   float
    viewportKind*: int
    zoom*:         float


  CCamera* = object
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


  CTransform* = object
    rotation*: Quat
    position*: Vec3
    scale*:    Vec3
    euler*:    Vec3


  CObject* = object
    parent*: Ent
    childs*: seq[Ent]
  

  CSprite* = object
    color*: Color
    data*:  Sprite


  CInteraction* = object
    rect*: Rect
    onClick*: proc()

type
  Object* = distinct Ent
  Camera* = distinct Ent


converter toEnt*(self: Object): Ent = self.Ent

converter toObj*(self: Camera): Object = self.Object
converter toEnt*(self: Camera): Ent = self.Ent