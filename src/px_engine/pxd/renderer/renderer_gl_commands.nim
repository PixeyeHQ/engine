import ../../px_engine_toolbox
import ../../px_engine_assets
import ../../vendors/[gl, stb_image, sdl]
import ../[api, m_math, m_vars, m_debug, m_memory]
import ../../p2d/api
import renderer_gl
import renderer_d

type
  Render2D_Kind* = enum
    R2D_NONE,
    R2D_GEOMETRY,
    R2D_SPRITE,
    R2D_FONT
  Render2D_State* = ref object
    ## Set of variables and configurations that control how graphics are rendered in a given frame.
    va*: VertexArray
    vb*: VertexBuffer
    ib*: IndexBuffer
    batch*:  Batch2d
    shader*: Shader
    textureId*: u32
    vertexLayout*:  VertexLayout
    defaultShader*: Shader
  Render2D_Context* = ref object
    ## A central point for managing all aspects of 2D rendering.
    state*:      Render2D_State
    renderKind*: Render2D_Kind
    texWhiteId*: u32
    # Font stuff
    fontShader*: Shader
    font*: Font
    fontDefault*: Font
    textBounds*: Vec2
    textParseIndex*: int
    textLineSpacing*: float

var render2d_context* = Render2D_Context()
let assets       = pxd.assets.getPack("renderer")
let app_screen_w = pxd.vars.get("app.screen.w", int)
let app_screen_h = pxd.vars.get("app.screen.h", int)
let runtime_screen_ratio = pxd.vars.get("runtime.screen.ratio", float)
let runtime_viewport_w   = pxd.vars.get("runtime.viewport.w", float)
let runtime_viewport_h   = pxd.vars.get("runtime.viewport.h", float)
let runtime_ppu          = pxd.vars.get("runtime.ppu", float)
let runtime_drawcalls    = pxd.vars.get("runtime.drawcalls", int)
#------------------------------------------------------------------------------------------
# @api opengl utils
#------------------------------------------------------------------------------------------
proc getAttributeInfo(vatype: VertexAttributeType): tuple[paramsCount: i32, attributeType: u32] =
  case (vatype):
    of float1:
      result = (paramsCount: i32(1), attributeType: u32(cGL_FLOAT))
    of float2:
      result = (paramsCount: i32(2), attributeType: u32(cGL_FLOAT))
    of float3:
      result = (paramsCount: i32(3), attributeType: u32(cGL_FLOAT))
    of float4:
      result = (paramsCount: i32(4), attributeType: u32(cGL_FLOAT))


proc rdSizeof*(typeId: u32): i32 =
  case typeId:
  of cGL_FLOAT: result = i32(sizeof(GLfloat))
  of GL_UNSIGNED_INT: result = i32(sizeof(GLuint))
  of GL_UNSIGNED_BYTE: result = i32(sizeof(GLByte))
  else:
    assert false
    result = 0


#------------------------------------------------------------------------------------------
# @api opengl arrays and buffers
#------------------------------------------------------------------------------------------
# opengl vertex array
#------------------------------------------------------------------------------------------
proc use*(api: RenderAPI, self: var VertexArray) =
  glBindVertexArray(self.id)


proc stop*(api: RenderAPI, self: var VertexArray) =
  glBindVertexArray(0)


proc delete*(api: RenderAPI, self: var VertexArray) =
  glDeleteVertexArrays(1, self.id.addr)


proc initVertexArray*(api: RenderAPI): VertexArray =
  glGenVertexArrays(1, result.id.addr)
  glBindVertexArray(result.id)


proc addLayout*(self: var VertexArray, layout: VertexLayout) =
  self.layout = layout
  for index, attribute in mpairs[u32, var VertexAttribute](self.layout.elements):
    let info = getAttributeInfo(attribute.vtype)
    glVertexAttribPointer(index, info.paramsCount, info.attributeType, attribute.normalized,
      layout.stride, cast[pointer](attribute.offset))
    glEnableVertexAttribArray(index)


#------------------------------------------------------------------------------------------
# opengl vertex buffers
#------------------------------------------------------------------------------------------
proc use*(api: RenderAPI, self: var VertexBuffer) =
  glBindBuffer(GL_ARRAY_BUFFER, self.id)


proc stop*(api: RenderAPI, self: var VertexBuffer) =
  glBindBuffer(GL_ARRAY_BUFFER, 0)


proc delete*(api: RenderAPI, self: var VertexBuffer) =
  glDeleteBuffers(1, self.id.addr)


proc initVertexBuffer*(api: RenderAPI, vertexType: typedesc, count: int): VertexBuffer =
  glGenBuffers(1, result.id.addr)
  glBindBuffer(GL_ARRAY_BUFFER, result.id)
  glBufferData(GL_ARRAY_BUFFER, (sizeof(vertexType)*count).cint, nil, GL_DYNAMIC_DRAW)


proc add*(layout: var VertexLayout, vaType: VertexAttributeType, name: string, normalized: bool = false) =
  var attribute: VertexAttribute
  let attributeInfo = getAttributeInfo(vaType)
  attribute.vtype = vaType
  attribute.name = name
  attribute.normalized = normalized
  attribute.offset = layout.stride
  layout.stride += i32(attributeInfo.paramsCount * rdsizeof(attributeInfo.attributeType))
  layout.elements.add(attribute)


proc initVertexLayout*(api: RenderAPI): VertexLayout =
  result.elements = newseq[VertexAttribute]()


#---------------------------------------------------------------------------------------------
# index buffers
#---------------------------------------------------------------------------------------------
using self: var IndexBuffer


proc exists*(api: RenderAPI, self; ): bool =
  result = self.id != 0


proc use*(api: RenderAPI, self; ) =
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, self.id)


proc stop*(api: RenderAPI, self; ) =
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0)


proc delete*(api: RenderAPI, self; ) =
  glDeleteBuffers(1, self.id.addr)


proc initIndexBuffer*(api: RenderAPI, data: pointer, count: int): IndexBuffer =
  var ib: IndexBuffer
  ib.count = count.i32
  glGenBuffers(1, ib.id.addr)
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ib.id)
  glBufferData(GL_ELEMENT_ARRAY_BUFFER, (count * sizeof(GLuint)).cint, data, GL_STATIC_DRAW)
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0)
  result = ib


#---------------------------------------------------------------------------------------------
#@api framebuffers
#---------------------------------------------------------------------------------------------
proc initFrameBuffer*(api: RenderAPI): u32 =
  glGenFramebuffers(1, result.addr) 
  glBindFramebuffer(GL_FRAMEBUFFER, 0)
  result


proc useFramebuffer*(api: RenderAPI, fboId: u32) =
  glBindFramebuffer(GL_FRAMEBUFFER, fboId)


proc stopFramebuffer*(api: RenderAPI) =
  glBindFramebuffer(GL_FRAMEBUFFER, 0)


proc attachFramebuffer*(api: RenderAPI,
    fboId: u32,
    texId: u32,
    attachType: RD_ATTACHMENT,
    texType:    RD_ATTACHMENT_FRAMEBUFFER
  ) =
  api.useFramebuffer(fboId)
  case attachType:
    of RD_COLOR_CHANNEL_0,
       RD_COLOR_CHANNEL_1,
       RD_COLOR_CHANNEL_2,
       RD_COLOR_CHANNEL_3,
       RD_COLOR_CHANNEL_4,
       RD_COLOR_CHANNEL_5,
       RD_COLOR_CHANNEL_6,
       RD_COLOR_CHANNEL_7:
      if texType == RD_FB_TEXTURE2D:
        glFramebufferTexture2D(
          GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0 + ord(attachType).u32, GL_TEXTURE_2D, texId, 0)
    of RD_DEPTH:
      if texType == RD_FB_TEXTURE2D:
        glFramebufferTexture2D(
          GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, texId, 0)
    of RD_STENCIL:
      discard


proc completeFramebuffer*(api: RenderAPI, fboId: u32): bool =
  api.useFramebuffer(fboId)
  let status = glCheckFramebufferStatus(GL_FRAMEBUFFER)
  case status:
    of GL_FRAMEBUFFER_UNSUPPORTED:
      pxd.debug.warn("FBO: Framebuffer is unsupported")
    of GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT:
      pxd.debug.warn("FBO: Framebuffer has incomplete attachment")
    of GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS:
      pxd.debug.warn("FBO: Framebuffer has incomplete dimensions")
    of GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT:
      pxd.debug.warn("FBO: Framebuffer has a missing attachment")
    else:
      discard
  api.stopFramebuffer()
  result = status == GL_FRAMEBUFFER_COMPLETE


#------------------------------------------------------------------------------------------
# @api Render2D, methods
#------------------------------------------------------------------------------------------
proc flush*(self: Render2D_Context) {.inline.} =
  let state = self.state
  if state.batch.nextVertexIndex == 0:
    return
  let frame = pxd.render.frame
  glActiveTexture(GL_TEXTURE0)
  glBindTexture(GL_TEXTURE_2D, state.textureId)
  # prepare batch
  pxd.render.use(state.vb)
  glBufferSubData(GL_ARRAY_BUFFER, 0, (sizeof(Vertex2d) * state.batch.nextVertexIndex).cint, state.batch.vertices[0].addr)
  pxd.render.stop(state.vb)
  # render
  pxd.render.use(state.shader)
  state.shader.uniform("umvp", frame.umvp)
  pxd.render.use(state.va)
  if state.batch.indexCount > 0:
    pxd.render.use(state.ib)
    glDrawElements(GL_TRIANGLES, state.batch.indexCount, GL_UNSIGNED_INT, nil)
    pxd.render.stop(state.ib)
  else:
    glDrawArrays(GL_TRIANGLES, 0, state.batch.nextVertexIndex)
  pxd.render.stop(state.va)
  pxd.render.stop(state.shader)
  state.batch.nextVertexIndex = 0
  state.batch.indexCount = 0
  runtime_drawcalls[] += 1


proc tryFlush*(self: Render2D_Context, nextVerticesCount: int) =
  let state = self.state
  if state.batch.indexCount >= R2D_QUADS_INDICES_BATCH or
     state.batch.nextVertexIndex >= R2D_QUADS_VERTICES_BATCH - nextVerticesCount:
     self.flush()


template tryFlush*(self: Render2D_Context, kind: Render2D_Kind, pvertexCount: int) =
  if self.renderKind != kind:
    self.flush()
    self.renderKind = kind
  self.tryFlush(pvertexCount)


proc setShader*(self: Render2D_Context, shader: Shader) =
  self.flush()
  self.state.defaultShader = shader
  self.state.shader = self.state.defaultShader


template useShader*(self: Render2D_Context, pshader: Shader, code: untyped) =
  block:
    self.flush()
    self.state.shader = pshader
    pxd.render.use(pshader)
    block:
      code
    self.flush()
    pxd.render.stop(pshader)
    self.state.shader = self.state.defaultShader


template useShader*(self: Render2D_Context, code: untyped) =
  block:
    self.flush()
    self.state.shader = self.state.defaultShader
    pxd.render.use(self.state.shader)
    block:
      code
    pxd.render.stop(self.state.shader)


{.push inline.}
proc useShader*(self: Render2D_Context) =
  self.flush()
  self.state.shader = self.state.defaultShader


proc useShader*(self: Render2D_Context, pshader: Shader) =
  self.flush()
  self.state.shader = pshader


proc uniform*(self: Render2D_Context, name: string, value: i32) =
  self.flush()
  pxd.render.use(self.state.shader)
  self.state.shader.uniform(name, value)


proc uniform*(self: Render2D_Context, name: string, count: int, value: ptr i32) =
  self.flush()
  pxd.render.use(self.state.shader)
  self.state.shader.uniform(name, count, value)


proc uniform*(self: Render2D_Context, name: string, value: f32) =
  self.flush()
  pxd.render.use(self.state.shader)
  self.state.shader.uniform(name, value)


proc uniform*(self: Render2D_Context, name: string, x, y, z, w: f32) =
  self.flush()
  pxd.render.use(self.state.shader)
  self.state.shader.uniform(name, x, y, z, w)


proc uniform*(self: Render2D_Context, name: string, value: Vec) =
  self.flush()
  pxd.render.use(self.state.shader)
  self.state.shader.uniform(name, value.x, value.y, value.z, value.w)


proc uniform*(self: Render2D_Context, name: string, matrix: var Matrix) =
  self.flush()
  pxd.render.use(self.state.shader)
  self.state.shader.uniform(name, matrix)
{.pop.}



#------------------------------------------------------------------------------------------
# @api p2d, methods
#------------------------------------------------------------------------------------------
template addVertexLayout2D(self: Render2D_State) {.dirty.} =
  var layout = pxd.render.initVertexLayout()
  layout.add(float4, "color")
  layout.add(float3, "position")
  layout.add(float2, "texcoord")
  self.vertexLayout = layout
  self.va.addLayout(layout)


template addQuadIndexBuffer(self: Render2D_State) {.dirty.} =
  var indices: array[R2D_QUADS_INDICES_BATCH, i32]
  var indexOffset = 0.i32
  for index in countup(0, indices.high, 6):
    indices[index+0] = 0 + indexOffset
    indices[index+1] = 1 + indexOffset
    indices[index+2] = 2 + indexOffset
    indices[index+3] = 2 + indexOffset
    indices[index+4] = 3 + indexOffset
    indices[index+5] = 0 + indexOffset
    indexOffset += 4
  self.ib = pxd.render.initIndexBuffer(indices.addr, indices.len)


proc initRender2d*(api: EngineAPI) =
  # load
  assets.load("./shaders/px_2d.shader", Shader)
  assets.load("./shaders/px_font.shader", Shader)
  #assets.load("./fonts/iosevka_sdf.fnt", Font) #todo: need basic font
  # init
  let r2d_ctx = render2d_context
#  r2d_ctx.fontDefault = assets.get("./fonts/iosevka_sdf.fnt", Font)
  r2d_ctx.fontShader  = assets.get("./shaders/px_font.shader", Shader)
  r2d_ctx.texWhiteId = pxd.assets.getTextureWhite().get.id
  r2d_ctx.state = Render2D_State()
  r2d_ctx.font  = r2d_ctx.fontDefault
  let r2d_s = r2d_ctx.state
  r2d_s.batch.vertices = newSeq[Vertex2d](R2D_QUADS_VERTICES_BATCH)
  r2d_s.defaultShader  = assets.get("./shaders/px_2d.shader", Shader)
  r2d_s.va = pxd.render.initVertexArray()
  r2d_s.vb = pxd.render.initVertexBuffer(Vertex2d, R2D_QUADS_VERTICES_BATCH)
  r2d_s.addVertexLayout2D()
  r2d_s.addQuadIndexBuffer()
  pxd.render.stop(r2d_s.vb)
  pxd.render.stop(r2d_s.va)
  render2d_context.setShader(r2d_s.defaultShader)


proc render*(api: P2dAPI): Render2D_Context =
  ## A central point for managing all aspects of 2D rendering.
  render2d_context


proc flush*(api: RenderAPI) =
  p2d.render.flush()


proc clear*(api: RenderAPI, r, g, b: f64) =
  glClearColor(r, g, b, 1.0)
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)
  glClearDepth(1.0)


proc clear*(api: RenderAPI) =
  glClearColor(0, 0, 0, 0)
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)
  glClearDepth(1.0)


proc viewport*(api: RenderAPI, x: int, y: int) =
  let aspectRatio = runtime_screen_ratio[]
  var aspectWidth  = x.f32
  var aspectHeight = aspectWidth / aspectRatio
  if aspectHeight > y.f32:
    aspectHeight = y.f32
    aspectWidth  = aspectHeight * aspectRatio
  let viewportx = i32(x / 2 - aspectWidth.f32 / 2)
  let viewporty = i32(y / 2 - aspectHeight.f32 / 2)
  glViewport(viewportx,viewporty,aspectWidth.int,aspectHeight.int)
  runtime_viewport_w[] = aspectWidth - viewportx.f64
  runtime_viewport_h[] = aspectHeight - viewporty.f64


proc viewportScreen*(api: RenderAPI, x: int, y: int) =
  let aspectRatio = runtime_screen_ratio[]
  var aspectWidth  = x.f32
  var aspectHeight = aspectWidth / aspectRatio
  if aspectHeight > y.f32:
    aspectHeight = y.f32
    aspectWidth  = aspectHeight * aspectRatio
  let viewportx = i32((x.f32  - aspectWidth.f32) / 2.0)
  let viewporty = i32((y.f32  - aspectHeight.f32) / 2.0)
  glViewport(viewportx,viewporty ,x.int, y.int)
  runtime_viewport_w[] = aspectWidth - viewportx.f64
  runtime_viewport_h[] = aspectHeight - viewporty.f64


proc target*(api: RenderAPI, _: ScreenMode, x: int = app_screen_w[], y: int = app_screen_h[]) =
  proc getScreenMatrix(): Matrix =
    var cameraPos {.global.} = vec(0, 0, 100)
    var translation = matrixIdentity()
    result = matrixIdentity()
    result = multiply(result, translation)
    result.invert()
  pxd.render.flush()
  let w = x.f64
  let h = y.f64
  var m = getScreenMatrix()
  pxd.render.viewportScreen(w.int,h.int)
  pxd.render.frame.ppu = runtime_ppu[]
  pxd.render.frame.umvp.identity()
  pxd.render.frame.umvp.ortho(0, w, 0, h, 0.01, 1000)
  pxd.render.frame.umvp = multiply(pxd.render.frame.umvp, m)


proc depthTest*(api: RenderAPI, mode: static bool) =
  pxd.render.flush()
  when mode == true:
    glEnable(GL_DEPTH_TEST)
  else:
    glDisable(GL_DEPTH_TEST)
