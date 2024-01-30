import std/[strutils, strformat]
import ../[api, m_memory, m_debug, m_filesystem]
import ../../vendors/[stb_image]
import ../../assets/[asset_pack]

type
  ImageObj* = object
    width*: int
    height*: int
    components*: int
    memory*: Mem
  ImageDef* = ref object of RootObj
    flip_vertically*: bool = true


pxd.memory.genPool(Image, ImageObj, 10)


#------------------------------------------------------------------------------------------
# @api image loader
#------------------------------------------------------------------------------------------
proc load*(api: AssetAPI, relativePath: string, _: typedesc[Image], def: ImageDef): Image =
  var w, h, bits: cint
  let path = pxd.filesystem.path(relativePath)
  stbi_set_flip_vertically_on_load((cint(ord def.flip_vertically)))
  var data = stbi_load(cstring(path), w, h, bits, STB_IMAGE_DEFAULT)
  var reason = $stbi_failure_reason()
  if reason != "no SOI" and reason != default(string):
    #png file always gives this error. It's ok
    pxd.debug.warn("ASSETS: " & stbi_failure_reason())
  var image_asset = make(Image)
  image_asset.width = w
  image_asset.height = h
  image_asset.components = bits
  image_asset.memory = pxd.memory.initMem(w * h * bits)
  copyMem(image_asset.get.memory.data, data, w * h * bits)
  stbi_image_free(data)
  result = image_asset


proc load*(api: AssetAPI, relativePath: string, typeof: typedesc[Image]): Image =
  api.load(relativePath, typeof, ImageDef())


proc load*(pack: AssetPack, relativePath: string, typeof: typedesc[Image], def: ImageDef): Image {.discardable.} =
  var tag = relativePath & $typeof
  result = pxd.asset.load(relativePath, typeof, def)
  pack.items[tag] = (Handle)result


proc load*(pack: AssetPack, relativePath: string, typeof: typedesc[Image]): Image {.discardable.} =
  pack.load(relativePath, typeof, ImageDef())


proc unload*(api: AssetAPI, image: Image) =
  image.width = 0
  image.height = 0
  image.components = 0
  pxd.memory.freeMem(image.memory)
  image.drop()


# proc handle*(api: AssetAPI, relativePath: string, typeof: typedesc[Image]): Asset[Image] =
#   result.path = relativePath
# # proc freeObj*(self: var ImageObj) =
# #   self.data.setLen(0)
# #   self.width      = 0
# #   self.height     = 0
# #   self.components = 0


# # proc onDrop(handle: Image) =
#  #   freeObj(handle.get)


# # proc image*(api: var Assets, assetName: string): Image {.discardable, inline.} =
# #   result = imageStore.get(assetName, proc(): ImageObj = loadImage(assetName))


# # proc images*(api: var Assets): var ObjPool[ImageObj, Image] {.inline.} =
# #   imageStore
