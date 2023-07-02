import px_engine/vendor/gl
import px_engine/pxd/definition/api
import px_engine/pxd/m_debug
import px_engine/pxd/m_math
import px_engine/pxd/m_metrics_app
import px_engine/pxd/m_res
import px_engine/pxd/data/data_mem_pool
import renderer_d
import renderer_gl


type Render2DKind* = enum
  R2D_NONE,
  R2D_GEOMETRY,
  R2D_SPRITE,
  R2D_FONT


type DynamicRenderer2D_Obj = object
  renderer*:    Renderer2D
  texWhite*:    Texture2D
  texWhiteId*:  u32
  renderKind*:  Render2D_Kind
  fontShader*:  Shader
  font*:        Font
  fontDefault*: Font
  textBounds*:      Vec2
  textParseIndex*:  int
  textLineSpacing*: float
type DynamicRenderer2D* = distinct Handle


GEN_MEM_POOL(Renderer2D_Obj, Renderer2D)
GEN_MEM_POOL(DynamicRenderer2D_Obj, DynamicRenderer2D)


#------------------------------------------------------------------------------------------
# @api state
#------------------------------------------------------------------------------------------
let dynamicRender   = make(DynamicRenderer2D_Obj)
let shapeRender_h   = make(Renderer2D_Obj)
let spriteRender_h  = make(Renderer2D_Obj)
let textRender_h    = make(Renderer2D_Obj)
let internal        = pxd.render.internal


#------------------------------------------------------------------------------------------
# @api Render2D, methods
#------------------------------------------------------------------------------------------
proc use*(api: Renderer2D, shader: Shader) {.inline.} =
  internal.use(shader)


proc stop*(api: Renderer2D, shader: Shader) {.inline.} =
  internal.stop(shader)


proc flush*(self: Renderer2D) {.inline.} =
  if self.batch.nextVertexIndex == 0:
    return
  let frame = pxd.render.frame.addr
  glActiveTexture(GL_TEXTURE0)
  glBindTexture(GL_TEXTURE_2D, self.textureId)
  # prepare batch
  internal.use(self.vb)
  glBufferSubData(GL_ARRAY_BUFFER, 0, (sizeof(Vertex2d) * self.batch.nextVertexIndex).cint, self.batch.vertices[0].addr)
  internal.stop(self.vb)
  # render
  internal.use(self.shader)
  self.shader.uniform("umvp", frame.umvp)
  internal.use(self.va)
  if self.batch.indexCount > 0:
    internal.use(self.ib)
    glDrawElements(GL_TRIANGLES, self.batch.indexCount, GL_UNSIGNED_INT, nil)
    internal.stop(self.ib)
  else:
    glDrawArrays(GL_TRIANGLES, 0, self.batch.nextVertexIndex)
  internal.stop(self.va)
  internal.stop(self.shader)
  self.batch.nextVertexIndex = 0
  self.batch.indexCount      = 0
  pxd.metrics.app.state.drawcalls += 1


proc tryFlush*(self: Renderer2D) =
  if self.batch.indexCount >= R2D_QUADS_INDICES_BATCH or
     self.batch.nextVertexIndex >= R2D_QUADS_VERTICES_BATCH:
       self.flush()


proc tryFlush*(self: Renderer2D, nextVerticesCount: int) =
  if self.batch.indexCount >= R2D_QUADS_INDICES_BATCH or
     self.batch.nextVertexIndex >= R2D_QUADS_VERTICES_BATCH - nextVerticesCount:
       self.flush()


proc setShader*(self: Renderer2D, shader: Shader) =
  self.flush()
  self.defaultShader = shader
  self.shader        =  self.defaultShader


template useShader*(self: Renderer2D, pshader: Shader, code: untyped) =
  block:
    self.flush()
    self.shader = pshader
    internal.use(self.shader)
    block:
      code
    self.flush()
    self.shader = self.defaultShader


template useShader*(self: Renderer2D, code: untyped) =
  block:
    self.flush()
    internal.use(self.shader)
    block:
      code
    internal.stop(self.shader)


{.push inline.}
proc uniform*(self: Renderer2D, name: string, value: i32) =
  self.shader.uniform(name, value)


proc uniform*(self: Renderer2D, name: string, count: int, value: ptr i32) =
  self.shader.uniform(name, count, value)


proc uniform*(self: Renderer2D, name: string, value: f32) =
  self.shader.uniform(name, value)


proc uniform*(self: Renderer2D, name: string, x,y,z,w: f32) =
  self.shader.uniform(name, x,y,z,w)


proc uniform*(self: Renderer2D, name: string, value: Vec) =
  self.shader.uniform(name, value.x, value.y, value.z, value.w)


proc uniform*(self: Renderer2D, name: string, matrix: var Matrix) =
  self.shader.uniform(name,matrix)
{.pop.}


#------------------------------------------------------------------------------------------
# @api r2d, draw commands
#------------------------------------------------------------------------------------------
template setTypeRenderer2D*(kind: Render2D_Kind) =
  if dynamicRender.renderKind != kind:
    dynamicRender.renderer.flush()
    dynamicRender.renderKind = kind


template draw*(self: Renderer2D, pindexCount: static int, pvertexCount: int, kind: Render2D_Kind, code: untyped) {.dirty.} =
  let renderer = self
  setTypeRenderer2D(kind)
  renderer.tryFlush(pvertexCount)
  let batch         = renderer.batch.addr
  let buffer        = batch.vertices.addr
  var nvertexColor: Color
  block:
    code
  batch.indexCount += pindexCount


template color*(color: Color) {.dirty.} =
  nvertexColor = color


template texture*(id: u32) {.dirty.} =
  if renderer.textureId != id:
    renderer.flush()
    renderer.textureId = id


template vertex*(pp: Vec3, pu: f32 = 0f, pv: f32 = 0f)  =
  var v = buffer[batch.nextVertexIndex].addr
  v.color      = nvertexColor
  v.position.x = pp.x
  v.position.y = pp.y
  v.position.z = pp.z
  v.texcoord.u = pu
  v.texcoord.v = pv
  inc batch.nextVertexIndex


template vertex*(px,py,pz: f32, pu: f32 = 0f, pv: f32 = 0f)  =
  var v = buffer[batch.nextVertexIndex].addr
  v.color      = nvertexColor
  v.position.x = px
  v.position.y = py
  v.position.z = pz
  v.texcoord.u = pu
  v.texcoord.v = pv
  inc batch.nextVertexIndex


template vertexr*(px,py,pz: f32, ox, oy: f32, cos: f32, sin: f32, pu: f32 = 0f, pv: f32 = 0f)  =
  let v = buffer[batch.nextVertexIndex].addr
  v.color      = nvertexColor
  v.position.x = (px - ox) * cos  - (py - oy) * -sin + ox
  v.position.y = (px - ox) * -sin + (py - oy) * cos + oy
  v.position.z = pz
  v.texcoord.u = pu
  v.texcoord.v = pv
  inc batch.nextVertexIndex


template vertex*(px,py,pz: f32, ptexcoord: Vec2)  =
  var v = buffer[batch.nextVertexIndex].addr
  v.color      = nvertexColor
  v.position.x = px
  v.position.y = py
  v.position.z = pz
  v.texcoord   = ptexcoord
  inc batch.nextVertexIndex


proc getLineRadius*(p1, p2: Vec3, thickness: f32): Vec {.inline.} =
  let direction    = p2 - p1
  let normalVector = direction.normalized()
  let radius       = thickness / 2
  result = vec(-radius * normalVector.y, radius * normalVector.x)


#------------------------------------------------------------------------------------------
# @api p2d, methods
#------------------------------------------------------------------------------------------
template addVertexLayout(self: ptr Renderer2D_Obj) {.dirty.} =
  var layout = internal.initVertexLayout()
  layout.add(float4, "color")
  layout.add(float3, "position")
  layout.add(float2, "texcoord")
  r.vertexLayout = layout
  r.va.addLayout(layout)


template addQuadIndexBuffer(self: ptr Renderer2D_Obj) {.dirty.} =
  var indices: array[R2D_QUADS_INDICES_BATCH,i32]
  var indexOffset = 0.i32
  for index in countup(0, indices.high, 6):
    indices[index+0] = 0 + indexOffset
    indices[index+1] = 1 + indexOffset
    indices[index+2] = 2 + indexOffset
    indices[index+3] = 2 + indexOffset
    indices[index+4] = 3 + indexOffset
    indices[index+5] = 0 + indexOffset
    indexOffset += 4
  r.ib = internal.addIndexBuffer(indices.addr, indices.len)


proc initDynamicRenderer() =
  let dr        = dynamicRender.get.addr
  dr.texWhite   = pxd.res.getTextureWhite()
  dr.texWhiteId = dr.texWhite.get.id
  dr.renderer   = make(Renderer2D_OBJ)
  dr.fontShader = pxd.res.get("./assets/shaders/pxd_font.shader").shader
  let r = dr.renderer.get.addr
  r.batch.vertices = newSeq[Vertex2d](R2D_QUADS_VERTICES_BATCH)
  r.shader         = pxd.res.get("./assets/shaders/r2d.shader").shader
  r.textureId      = pxd.res.getTextureWhite().get.id
  r.defaultShader  = r.shader
  r.va = internal.addVertexArray()
  r.vb = internal.addVertexBuffer(Vertex2d, R2D_QUADS_VERTICES_BATCH)
  r.addVertexLayout()
  r.addQuadIndexBuffer()
  internal.stop(r.vb)
  internal.stop(r.va)


proc initRenderer*(api: P2d_API) =
  initDynamicRenderer()


proc render2D*(api: Engine_API): DynamicRenderer2D =
  dynamicRender


proc executeRender*(api: P2d_API) =
  dynamicRender.renderer.flush()





