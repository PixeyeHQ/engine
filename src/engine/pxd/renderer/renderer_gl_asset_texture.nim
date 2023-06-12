import engine/vendor/stb_image
import engine/vendor/gl
import engine/pxd/api
import engine/pxd/data/m_mem_pool
import engine/pxd/data/m_mem
import engine/pxd/m_debug
import engine/pxd/assets/asset_image
import renderer_d


GEN_MEM_POOL(Texture2D_Obj, Texture2D)


#------------------------------------------------------------------------------------------
# @api texture2d load
#------------------------------------------------------------------------------------------
var textureWhite: Texture2D


proc load*(api: EngineAPI, path: string, pixelPerfect: bool, typeof: typedesc[Texture2D]): Texture2D =
  let image = engine.load(path, Image)
  result    = make(Texture2D_Obj)
  var w     = image.get.width
  var h     = image.get.height
  var format: GLenum
  case image.get.components:
    of 3:
      format = GL_RGB
    of 4:
      format = GL_RGBA
    else:
      debug.warn("[ASSET] Wrong texture format.")
  var FILTER = if pixelPerfect: GL_NEAREST else: GL_LINEAR
  glGenTextures(1, result.get.id.addr)
  glBindTexture(GL_TEXTURE_2D, result.get.id)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE.Glint)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE.Glint)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, FILTER.Glint)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, FILTER.Glint)
  glTexImage2D(GL_TEXTURE_2D, 0, format.GLint, w, h, 0, format, GL_UNSIGNED_BYTE, image.get.mem.data[0].addr)
  result.width  = w
  result.height = h
  engine.unload(image)


proc unload*(api: EngineAPI, texture: Texture2D) =
  glDeleteTextures(1, texture.get.id.addr)
  texture.drop()


proc genTextureWhite(): Texture2D =
  const GL_RGB_ID = GL_RGBA8.GLint
  var texture = make(Texture2D_Obj)
  var color = 0xffffffff
  var w = 1.int32
  var h = 1.int32
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


proc getTextureWhite*(api: ResAPI): Texture2D =
  if not textureWhite.alive:
    textureWhite = genTextureWhite()
  textureWhite


#   #glUniform1i(glGetUniformLocation(ourShader.ID, "texture1"), 0);



# proc loadTexture(assetName: string): TextureObj =
#   var image = loadImage(assetName)
#   result    = loadTexture(image)


# proc getTextureWhite*(api: var Assets): Texture =
#   const assetName = "textWhite"
#   const assetKey  = key(assetName)
#   if not storage.map.hasKey(assetKey):
#     result = storage.put(genTextureWhite(assetName), assetKey)
#   else:
#     result = storage.map[assetKey]


# proc getTexture*(api: var Assets, assetName: string): Texture {.discardable.} =
#   storage.get(assetName, proc():TextureObj = loadTexture(assetName))


# proc getTexture*(api: var Assets, image: Image): Texture {.discardable.} =
#   result = storage.put(loadTexture(image.get), key(image.get.assetName))


# proc textures*(api: var Assets): var ObjPool[TextureObj,Texture] {.inline.} =
#   storage





# # proc genTexture*(width: int, height: int): Texture =
# #   const GL_RGB_ID = GL_RGB.GLint
# #   var texture = Texture()
# #   glCreateTextures(GL_TEXTURE_2D, 1, texture.id.addr)
# #   glBindTexture(GL_TEXTURE_2D, texture.id)
# #   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST.Glint)
# #   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST.Glint)
# #   glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB_ID, width, height, 0, GL_RGB, GL_UNSIGNED_INT, nil)
# #   glBindTexture(GL_TEXTURE_2D, 0);
# #   result = texture

# # proc genTextureDepth*(width: int, height: int): Texture =
# #   var texture = Texture()
# #   glCreateTextures(GL_TEXTURE_2D, 1, texture.id.addr)
# #   glBindTexture(GL_TEXTURE_2D, texture.id)
# #   glTextureParameteri(texture.id, GL_TEXTURE_WRAP_S,     GL_CLAMP_TO_EDGE.Glint)
# #   glTextureParameteri(texture.id, GL_TEXTURE_WRAP_T,     GL_CLAMP_TO_EDGE.Glint)
# #   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST.Glint)
# #   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST.Glint)
# #   glTexImage2D(GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT.Glint, width, height, 0, GL_DEPTH_COMPONENT, GL_UNSIGNED_INT, nil)
# #   glBindTexture(GL_TEXTURE_2D, 0);
# #   result = texture


# # proc genTextureWhite*(): Texture =
# #   const GL_RGB_ID = GL_RGBA8.GLint
# #   var texture = Texture()
# #   var color = 0xffffffff
# #   glCreateTextures(GL_TEXTURE_2D, 1, texture.id.addr)
# #   glBindTexture(GL_TEXTURE_2D, texture.id)
# #   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE.Glint)
# #   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE.Glint)
# #   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR.Glint)
# #   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR.Glint)
# #   glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB_ID, 1, 1, 0, GL_RGBA, GL_UNSIGNED_BYTE, color.addr)
# #   result = texture
