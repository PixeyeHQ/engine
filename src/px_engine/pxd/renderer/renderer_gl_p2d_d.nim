import px_engine/pxd/definition/api
import px_engine/pxd/res/asset_shader
import renderer_gl_d


type Renderer2D_Obj* = object
  va*:            VertexArray
  vb*:            VertexBuffer
  ib*:            IndexBuffer
  batch*:         Batch2d
  shader*:        Shader
  textureId*:     u32
  vertexLayout*:  VertexLayout
  defaultShader*: Shader


type Renderer2D* = distinct Handle