import ../[api, m_math, m_vars]
import renderer_gl_commands


#------------------------------------------------------------------------------------------
# @api r2d, draw commands
#------------------------------------------------------------------------------------------
template draw*(pindexCount: static int, pvertexCount: int, kind: Render2D_Kind,
    code: untyped) {.dirty.} =
  let renderer = render2d_context
  renderer.tryFlush(kind, pvertexCount)
  let batch  = renderer.state.batch.addr
  let buffer = batch.vertices.addr
  var nvertexColor: Color
  block:
    code
  batch.indexCount += pindexCount


template color*(color: math_d.Color) {.dirty.} =
  nvertexColor = color


template texture*(id: u32) {.dirty.} =
  if renderer.state.textureId != id:
    renderer.flush()
    renderer.state.textureId = id


template vertex*(pp: Vec3, pu: f32 = 0f, pv: f32 = 0f) =
  var v = buffer[batch.nextVertexIndex].addr
  v.color = nvertexColor
  v.position.x = pp.x
  v.position.y = pp.y
  v.position.z = pp.z
  v.texcoord.u = pu
  v.texcoord.v = pv
  inc batch.nextVertexIndex


template vertex*(px, py, pz: f32, pu: f32 = 0f, pv: f32 = 0f) =
  var v = buffer[batch.nextVertexIndex].addr
  v.color = nvertexColor
  v.position.x = px
  v.position.y = py
  v.position.z = pz
  v.texcoord.u = pu
  v.texcoord.v = pv
  inc batch.nextVertexIndex


template vertexr*(px, py, pz: f32, ox, oy: f32, cos: f32, sin: f32, pu: f32 = 0f, pv: f32 = 0f) =
  let v = buffer[batch.nextVertexIndex].addr
  v.color = nvertexColor
  v.position.x = (px - ox) * cos - (py - oy) * -sin + ox
  v.position.y = (px - ox) * -sin + (py - oy) * cos + oy
  v.position.z = pz
  v.texcoord.u = pu
  v.texcoord.v = pv
  inc batch.nextVertexIndex


template vertex*(px, py, pz: f32, ptexcoord: Vec2) =
  var v = buffer[batch.nextVertexIndex].addr
  v.color = nvertexColor
  v.position.x = px
  v.position.y = py
  v.position.z = pz
  v.texcoord = ptexcoord
  inc batch.nextVertexIndex


proc getLineRadius*(p1, p2: Vec3, thickness: f32): Vec {.inline.} =
  let direction = p2 - p1
  let normalVector = direction.normalized()
  let radius = thickness / 2
  result = vec(-radius * normalVector.y, radius * normalVector.x)
