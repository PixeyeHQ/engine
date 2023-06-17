import px_engine/vendor/gl
import px_engine/pxd/api
import px_engine/pxd/m_math
import px_engine/pxd/data/m_mem_d


type ShaderError* = enum
  RE_SHADER_NO_VERT_FILE,
  RE_SHADER_NO_FRAG_FILE


type ShaderObj* = object
  program*: uint32


type Shader* = distinct Handle


type VertexAttributeType* {.pure, size: uint32.sizeof.} = enum
  float4,
  float3,
  float2,
  float1


type VertexAttribute* = tuple[
  vtype: VertexAttributeType,
  name: string,
  normalized: bool,
  offset: int
]


type VertexLayout* = object
  elements*: seq[VertexAttribute]
  stride*:   int32


type VertexBuffer* = object
  id*: uint32


type VertexArray* = object
  id*: uint32
  layout*: VertexLayout


type IndexBuffer* = object
  id*:    uint32
  count*: int32


type TextureObj* = object
  id*:     uint32
  width*:  int32
  height*: int32


type Texture* = distinct uint32


type Texture2D_Obj* = object
  id*:     uint32
  width*:  i32
  height*: i32


type Texture2D* = distinct Handle


type ImageObj* = object
  width*:      int32
  height*:     int32
  components*: int
  mem*:        Mem


type Image* = distinct Handle


type Vertex2d* = object
  color*:    Color
  position*: Vec3
  texcoord*: Vec2
  # texindex*: float32


type Batch2d* = object
  nextVertexIndex*: int32
  indexCount*:      int32
  vertices*:        seq[Vertex2d]


type RenderFrame* = object
  umvp*:  Matrix
  uproj*: Matrix
  uview*: Matrix


const
  RD_POINT*:          uint32 = 0x0000
  RD_LINE*:           uint32 = 0x0001
  RD_LINE_STRIP*:     uint32 = 0x0003
  RD_TRIANGLE*:       uint32 = 0x0004
  RD_TRIANGLE_STRIP*: uint32 = 0x0005
  RD_DEPTH_TEST*:     uint32 = 0x0B71
  RD_CULL_FACE*:      uint32 = 0x0B44
  RD_BLEND*:               uint32 = 0x0BE2
  RD_SRC_ALPHA*:           uint32 = 0x0302
  RD_ONE_MINUS_SRC_ALPHA*: uint32 = 0x0303
  RD_DEPTH_BUFFER_BIT*:    uint32 = 0x00000100
  RD_STENCIL_BUFFER_BIT*:  uint32 = 0x00000400
  RD_COLOR_BUFFER_BIT*:    uint32 = 0x00004000


const
  R2D_QUADS_BATCH* {.intdefine.}: int = 0
  R2D_QUADS_INDICES_BATCH*:       int = R2D_QUADS_BATCH * 6
  R2D_QUADS_VERTICES_BATCH*:      int = R2D_QUADS_BATCH * 4
  
  RD_FALSE*:            GLboolean = false
  RD_TRUE*:             GLboolean = true
  # PX_GL_UNSIGNED_INT*:  GLenum    = GLenum(0x1405)
  # PX_GL_INT*:           GLenum    = GLenum(0x1404)
  # PX_GL_FLOAT*:         GLenum    = GLenum(0x1406)
  # PX_GL_UNSIGNED_BYTE*: GLenum    = GLenum(0x1401)


converter tou32*(t: GLenum): uint32 =
  t.uint32


converter toGlenum*(t: uint32): GLenum =
  t.GLenum
