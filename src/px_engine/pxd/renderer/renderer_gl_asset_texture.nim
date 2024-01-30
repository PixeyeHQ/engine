import std/tables
import ../../vendors/gl
import ../../assets/[asset_image, asset_pack]
import ../[api, m_memory, m_debug]
import renderer_gl_d

type
  Texture2D*     = distinct Handle
  Texture2D_Obj* = object
    id*: u32
    width*: int
    height*: int
  Texture2D_Params* = ref object of Obj
    pixelPerfect*: bool = true
    channels*: int = 4
    width*:  int
    height*: int
    pixels*: seq[u8]
  RenderTexture* = object
    id*: u32
    texture*:      Texture2D
    textureDepth*: Texture2D

pxd.memory.genPoolTyped(Texture2D, Texture2D_Obj, 10)


var
  textureWhite: Texture2D
  textureAssets = initTable[string, Texture2D]()


#------------------------------------------------------------------------------------------
# @api texture2d load
#------------------------------------------------------------------------------------------
proc load*(api: AssetAPI, relativePath: string, _: typedesc[Texture2D], params: Texture2D_Params): Texture2D {.discardable.} =
  let image = pxd.assets.load(relativePath, Image)
  result = make(Texture2D)
  var w = image.width
  var h = image.height
  var format : GLenum
  case image.components:
    of 3:
      format = GL_RGB
    of 4:
      format = GL_RGBA
    else:
      pxd.debug.warn("ASSET: Wrong texture format")
  var FILTER = if params.pixelPerfect: GL_NEAREST else: GL_LINEAR
  glGenTextures(1, result.get.id.addr)
  glBindTexture(GL_TEXTURE_2D, result.get.id)
  var a = (Glint)GL_CLAMP_TO_EDGE
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, (Glint)GL_CLAMP_TO_EDGE)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, (Glint)GL_CLAMP_TO_EDGE)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, (Glint)FILTER)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, (Glint)FILTER)
  glTexImage2D(GL_TEXTURE_2D, GLint(0), (Glint)format, GLsizei(w), GLsizei(h), 0, format, GL_UNSIGNED_BYTE, image.get.memory.data[0].addr)
  result.width  = w
  result.height = h
  pxd.assets.unload(image)


proc load*(api: AssetAPI, params: Texture2D_Params, typeof: typedesc[Texture2D]): Texture2D =
  result    = make(Texture2D)
  let w     = params.width.i32
  let h     = params.height.i32
  var format: GLenum
  case params.channels:
    of 3:
      format = GL_RGB
    of 4:
      format = GL_RGBA
    else:
      pxd.debug.warn("ASSET: Wrong texture format.")
  var FILTER = if params.pixelPerfect: GL_NEAREST else: GL_LINEAR
  glGenTextures(1, result.get.id.addr)
  glBindTexture(GL_TEXTURE_2D, result.get.id)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, (Glint)GL_CLAMP_TO_EDGE)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, (Glint)GL_CLAMP_TO_EDGE)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, (Glint)FILTER)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, (Glint)FILTER)
  glTexImage2D(GL_TEXTURE_2D, 0, (Glint)format, w, h, 0, format, GL_UNSIGNED_BYTE, params.pixels[0].addr)
  result.width  = w
  result.height = h


proc load*(api: AssetAPI, relativePath: string, typeof: typedesc[Texture2D]): Texture2D =
  api.load(relativePath, typeof, Texture2D_Params())


proc load(relativePath: string, data: Obj): Handle {.nimcall.} =
  var res: Texture2D
  if isNil(data):
    res = pxd.assets.load(relativePath, Texture2D)
  else:
    res = pxd.assets.load(relativePath, Texture2D, Texture2D_Params(data))
  (Handle)res


proc load*(pack: AssetPack, relativePath: string, typeof: typedesc[Texture2D], params: Texture2D_Params): Texture2D {.discardable.} =
  var tag = relativePath & $typeof
  result = pxd.assets.load(relativePath, typeof, params)
  pack.items[tag] = (Handle)result


proc load*(pack: AssetPack, relativePath: string, typeof: typedesc[Texture2D]): Texture2D {.discardable.} =
  pack.load(relativePath, typeof, Texture2D_Params())


proc unload*(api: AssetAPI, texture: Texture2D) =
  glDeleteTextures(1, texture.get.id.addr)
  texture.drop()
# proc load*(api: EngineAPI, path: string, pixelPerfect: bool, typeof: typedesc[Texture2D]): Texture2D =
#   let image = engine.load(path, Image)
#   result    = make(Texture2D)
#   var w     = image.get.width
#   var h     = image.get.height
#   var format: GLenum
#   case image.get.components:
#     of 3:
#       format = GL_RGB
#     of 4:
#       format = GL_RGBA
#     else:
#       pxd.debug.warn("[ASSET] Wrong texture format.")
#   var FILTER = if pixelPerfect: GL_NEAREST else: GL_LINEAR
#   glGenTextures(1, result.get.id.addr)
#   glBindTexture(GL_TEXTURE_2D, result.get.id)
#   var a = (Glint)GL_CLAMP_TO_EDGE
#   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, (Glint)GL_CLAMP_TO_EDGE)
#   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, (Glint)GL_CLAMP_TO_EDGE)
#   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, (Glint)FILTER)
#   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, (Glint)FILTER)
#   glTexImage2D(GL_TEXTURE_2D, 0, (Glint)format, w, h, 0, format, GL_UNSIGNED_BYTE, image.get.mem.data[0].addr)
#   result.width  = w
#   result.height = h
#   engine.unload(image)



# proc load*(api: EngineAPI, def: Texture2DDef, typeof: typedesc[Texture2D]): Texture2D =
#   result    = make(Texture2D)
#   let w     = def.width.i32
#   let h     = def.height.i32
#   var format: GLenum
#   case def.channels:
#     of 3:
#       format = GL_RGB
#     of 4:
#       format = GL_RGBA
#     else:
#       pxd.debug.warn("[ASSET] Wrong texture format.")
#   var FILTER = if def.pixelPerfect: GL_NEAREST else: GL_LINEAR
#   glGenTextures(1, result.get.id.addr)
#   glBindTexture(GL_TEXTURE_2D, result.get.id)
#   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, (Glint)GL_CLAMP_TO_EDGE)
#   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, (Glint)GL_CLAMP_TO_EDGE)
#   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, (Glint)FILTER)
#   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, (Glint)FILTER)
#   glTexImage2D(GL_TEXTURE_2D, 0, (Glint)format, w, h, 0, format, GL_UNSIGNED_BYTE, def.pixels[0].addr)
#   result.width  = w
#   result.height = h


# proc unload*(api: EngineAPI, texture: Texture2D) =
#   glDeleteTextures(1, texture.get.id.addr)
#   texture.drop()


proc genTextureWhite(): Texture2D =
  const GL_RGB_ID = GL_RGBA8.GLint
  var texture = make(Texture2D)
  var color = 0xffffffff
  var w = 1.i32
  var h = 1.i32
  glCreateTextures(GL_TEXTURE_2D, 1, texture.get.id.addr)
  glTextureParameteri(texture.get.id, GL_TEXTURE_WRAP_S,     GL_CLAMP_TO_EDGE.Glint)
  glTextureParameteri(texture.get.id, GL_TEXTURE_WRAP_T,     GL_CLAMP_TO_EDGE.Glint)
  glTextureParameteri(texture.get.id, GL_TEXTURE_MIN_FILTER, GL_LINEAR.Glint)
  glTextureParameteri(texture.get.id, GL_TEXTURE_MAG_FILTER, GL_LINEAR.Glint)
  glTextureStorage2D(texture.get.id, 1, GL_RGBA8, w, h)
  glTextureSubImage2D(texture.get.id,0,0,0,w,h,GL_RGBA,GL_UNSIGNED_BYTE, color.addr)
  texture.get.width  = w
  texture.get.height = h
  texture


proc getTextureWhite*(api: AssetAPI): Texture2D =
  if not textureWhite.alive:
    textureWhite = genTextureWhite()
  textureWhite


proc genTextureRGB*(api: RenderAPI, width: int, height: int): Texture2D =
  const GL_RGB_ID = GL_RGB.GLint
  var texture = make(Texture2D)
  texture.width = width
  texture.height = height
  glCreateTextures(GL_TEXTURE_2D, 1, texture.get.id.addr)
  glBindTexture(GL_TEXTURE_2D, texture.get.id)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST.Glint)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST.Glint)
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB_ID, width.i32, height.i32, 0, GL_RGB, GL_UNSIGNED_INT, nil)
  glBindTexture(GL_TEXTURE_2D, 0);
  result = texture


proc genTextureRGBA*(api: RenderAPI, width: int, height: int): Texture2D =
  const GL_RGBA_ID = GL_RGBA.GLint
  var texture = make(Texture2D)
  texture.width = width
  texture.height = height
  glCreateTextures(GL_TEXTURE_2D, 1, texture.get.id.addr)
  glBindTexture(GL_TEXTURE_2D, texture.get.id)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST.Glint)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST.Glint)
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA_ID, width.i32, height.i32, 0, GL_RGBA, GL_UNSIGNED_INT, nil)
  glBindTexture(GL_TEXTURE_2D, 0);
  result = texture


proc genTextureDepth*(api: RenderAPI, width: int, height: int): Texture2D =
  var texture = make(Texture2D)
  texture.width = width
  texture.height = height
  glCreateTextures(GL_TEXTURE_2D, 1, texture.get.id.addr)
  glBindTexture(GL_TEXTURE_2D, texture.get.id)
  glTextureParameteri(texture.get.id, GL_TEXTURE_WRAP_S,     GL_CLAMP_TO_EDGE.Glint)
  glTextureParameteri(texture.get.id, GL_TEXTURE_WRAP_T,     GL_CLAMP_TO_EDGE.Glint)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST.Glint)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST.Glint)
  glTexImage2D(GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT.Glint, width.i32, height.i32, 0, GL_DEPTH_COMPONENT, GL_UNSIGNED_INT, nil)
  glBindTexture(GL_TEXTURE_2D, 0);
  result = texture


proc renderTexture*(api: CreateAPI, width: SomeNumber, height: SomeNumber): RenderTexture =
  let w: int = width.int
  let h: int = height.int
  result.id = pxd.render.initFrameBuffer()
  if result.id > 0:
    pxd.render.useFramebuffer(result.id)
    result.texture      =  pxd.render.genTextureRGBA(w,h)
    result.textureDepth =  pxd.render.genTextureDepth(w,h)
    pxd.render.attachFramebuffer(
     result.id, result.texture.get.id, RD_COLOR_CHANNEL_0, RD_FB_TEXTURE2D)
    pxd.render.attachFramebuffer(
     result.id, result.textureDepth.get.id, RD_DEPTH, RD_FB_TEXTURE2D)
  if pxd.render.completeFramebuffer(result.id):
    pxd.debug.info("FBO: Framebuffer object created successfully")
    pxd.render.stopFrameBuffer()
  else:
    pxd.debug.warn("FBO: Framebuffer object can not be created")

