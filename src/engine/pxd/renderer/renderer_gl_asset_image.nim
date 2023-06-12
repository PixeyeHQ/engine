import engine/vendor/stb_image
import engine/pxd/api
import engine/pxd/data/m_mem_pool
import engine/pxd/data/m_mem
import engine/pxd/m_debug
import renderer_d


GEN_MEM_POOL(ImageObj, Image)

#------------------------------------------------------------------------------------------
# @api image loader
#------------------------------------------------------------------------------------------
proc load*(api: EngineAPI, path: string, typeof: typedesc[Image]): Image =
  var w,h,bits: cint
  stbi_set_flip_vertically_on_load(ord true)
  var data = stbi_load(path, w, h, bits, STB_IMAGE_DEFAULT)
  var reason = $stbi_failure_reason()
  if reason != "no SOI" and reason != default(string):
    #png file always gives this error. It's ok.
    debug.warn(stbi_failure_reason())
  
  var image_asset = make(ImageObj)
  image_asset.get.width      = w
  image_asset.get.height     = h
  image_asset.get.components = bits
  image_asset.get.mem        = engine.initMem(w * h * bits)
  copyMem(image_asset.get.mem.data, data, w * h * bits)
  stbi_image_free(data)
  result = image_asset


proc unload*(api: EngineAPI, image: Image) =
  image.width      = 0
  image.height     = 0
  image.components = 0
  engine.freeMem(image.mem)
  image.drop()


# proc freeObj*(self: var ImageObj) =
#   self.data.setLen(0)
#   self.width      = 0
#   self.height     = 0
#   self.components = 0


# proc onDrop(handle: Image) =
#   freeObj(handle.get)


# proc image*(api: var Assets, assetName: string): Image {.discardable, inline.} =
#   result = imageStore.get(assetName, proc(): ImageObj = loadImage(assetName))


# proc images*(api: var Assets): var ObjPool[ImageObj, Image] {.inline.} =
#   imageStore