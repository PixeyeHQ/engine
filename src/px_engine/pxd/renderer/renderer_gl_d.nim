import ../../vendors/gl
import ../api
import ../m_math


type
  RD_ATTACHMENT* {.pure.} = enum
    RD_COLOR_CHANNEL_0 = 0
    RD_COLOR_CHANNEL_1 = 1
    RD_COLOR_CHANNEL_2 = 2
    RD_COLOR_CHANNEL_3 = 3
    RD_COLOR_CHANNEL_4 = 4
    RD_COLOR_CHANNEL_5 = 5
    RD_COLOR_CHANNEL_6 = 6
    RD_COLOR_CHANNEL_7 = 7
    RD_DEPTH           = 100
    RD_STENCIL         = 200
  RD_ATTACHMENT_FRAMEBUFFER* {.pure.} = enum
    RD_FB_TEXTURE2D     = 100,
    RD_FB_RENDERBUFFER  = 200,
  VertexAttributeType* {.pure, size: uint32.sizeof.} = enum
    float4,
    float3,
    float2,
    float1
  VertexAttribute* = tuple[
    vtype: VertexAttributeType,
    name: string,
    normalized: bool,
    offset: int
  ]
  VertexLayout* = object
    elements*: seq[VertexAttribute]
    stride*:   i32
  VertexBuffer* = object
    id*: u32
  VertexArray* = object
    id*: u32
    layout*: VertexLayout
  IndexBuffer* = object
    id*:    u32
    count*: i32
  Vertex2d* = object
    color*:    Color
    position*: Vec3
    texcoord*: Vec2
  Batch2d* = object
    nextVertexIndex*: i32
    indexCount*:      i32
    vertices*:        seq[Vertex2d]
  RenderFrame* = ref object
    umvp*:  Matrix
    uproj*: Matrix
    uview*: Matrix
    ppu*:   float

const
  RD_POINT*:          u32 = 0x0000
  RD_LINE*:           u32 = 0x0001
  RD_LINE_STRIP*:     u32 = 0x0003
  RD_TRIANGLE*:       u32 = 0x0004
  RD_TRIANGLE_STRIP*: u32 = 0x0005
  RD_DEPTH_TEST*:     u32 = 0x0B71
  RD_CULL_FACE*:      u32 = 0x0B44
  RD_BLEND*:               u32 = 0x0BE2
  RD_SRC_ALPHA*:           u32 = 0x0302
  RD_ONE_MINUS_SRC_ALPHA*: u32 = 0x0303
  RD_DEPTH_BUFFER_BIT*:    u32 = 0x00000100
  RD_STENCIL_BUFFER_BIT*:  u32 = 0x00000400
  RD_COLOR_BUFFER_BIT*:    u32 = 0x00004000
  RD_FALSE*:            GLboolean = false
  RD_TRUE*:             GLboolean = true
  # PX_GL_UNSIGNED_INT*:  GLenum    = GLenum(0x1405)
  # PX_GL_INT*:           GLenum    = GLenum(0x1404)
  # PX_GL_FLOAT*:         GLenum    = GLenum(0x1406)
  # PX_GL_UNSIGNED_BYTE*: GLenum    = GLenum(0x1401)
const
  R2D_QUADS_BATCH* {.intdefine.}: int = 10_000
  R2D_QUADS_INDICES_BATCH*:       int = R2D_QUADS_BATCH * 6
  R2D_QUADS_VERTICES_BATCH*:      int = R2D_QUADS_BATCH * 4

converter tou32*(t: GLenum): u32 = t.u32
converter toGlenum*(t: u32): GLenum = t.GLenum
