import px_engine/vendor/stb_image
import px_engine/pxd/definition/api
import px_engine/pxd/data/data_mem_pool
import px_engine/pxd/data/data_mem
import px_engine/pxd/m_debug
import renderer_gl_asset_image_d
export renderer_gl_asset_image_d


GEN_MEM_POOL(Image_Object, Image)


let debug  = pxd.debug
let engine = pxd.engine
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
    pxd.debug.warn(stbi_failure_reason())
  
  var image_asset = make(Image_Object)
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
  pxd.engine.freeMem(image.mem)
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