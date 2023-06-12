import std/hashes
import std/tables
import std/os
import engine/m_io
import engine/px
import engine/pxd/api
import engine/pxd/data/m_mem_pool
import asset_d
import asset_shader
import asset_image
import asset_texture
import asset_sprite
import asset_font
import asset_audio


var assets = initTable[string, Asset]()
GEN_MEM_POOL(AssetObj, Asset, 1024)


proc get*(api: ResAPI, relativePath: string): Asset {.discardable.} =
  let path        = io.path(relativePath)
  if not assets.hasKey(path):
    assets[path] = make(AssetObj)
    assets[path].path      = path
    assets[path].pathHash  = hash(path)
  result = assets[path]


proc load*(api: ResAPI, relativePath: string): Asset {.discardable.} =
  result = api.get(relativePath)
  if result.assetId == HANDLE_NULL:
    var ext = io.pathExtension(result.path)
    case ext:
      of "shader":
        result.assetId = Handle(engine.load(result.path, Shader))
      of ["png", "tga"]:
        result.assetId = Handle(engine.load(result.path, true, Texture2D))
      else:
        discard


proc load*[T](api: ResAPI, relativePath: string, typeof: typedesc[T]): Asset {.discardable.} =
  result = api.get(relativePath)
  if result.assetId == HANDLE_NULL:
    when compiles(result.assetId = engine.load(result.path, typeof)):
      result.assetId = engine.load(result.path, typeof)


proc unload*(api: ResAPI, asset: Asset) =
  if asset.assetId != HANDLE_NULL:
    var ext = io.pathExtension(asset.path)
    case ext:
      of "shader":
        engine.unload(Shader(asset.assetId))
      of ["png", "tga"]:
        engine.unload(Texture2D(asset.assetId))
      else:
        discard
    asset.assetId = HANDLE_NULL
  asset.drop()


proc unload*(api: ResAPI, relativePath: string) =
  var asset = api.get(relativePath)
  api.unload(asset)


proc unload*[T](api: ResAPI, relativePath: string, typeof: typedesc[T]) =
  var asset = api.get(relativePath)
  engine.unload(T(asset.assetId))
  asset.drop()


proc shader*(asset: Asset): Shader =
  ## Convert asset to a shader.
  ## Loads asset if it wasn't loaded.
  if not Shader(asset.assetId).alive:
    asset.assetId = Handle(engine.load(asset.path, Shader))
  result = Shader(asset.assetId)


proc image*(asset: Asset): Image =
  ## Convert asset to a Image.
  ## Loads asset if it wasn't loaded.
  if not Image(asset.assetId).alive:
    asset.assetId = Handle(engine.load(asset.path, Image))
  result = Image(asset.assetId)


proc texture2d*(asset: Asset): Texture2D =
  ## Convert asset to a texture2d.
  ## Loads asset if it wasn't loaded.
  if not Texture2D(asset.assetId).alive:
    asset.assetId = Handle(engine.load(asset.path, true, Texture2D))
  result = Texture2D(asset.assetId)


proc spriteAtlas*(asset: Asset): SpriteAtlas =
  ## Convert asset to a sprite atlas.
  ## Loads asset if it wasn't loaded.
  if not SpriteAtlas(asset.assetId).alive:
    asset.assetId = Handle(engine.load(asset.path, SpriteAtlas))
  result = SpriteAtlas(asset.assetId)


proc font*(asset: Asset): Font =
  ## Convert asset to a font.
  ## Loads asset if it wasn't loaded.
  if not Font(asset.assetId).alive:
    asset.assetId = Handle(engine.load(asset.path, Font))
  result = Font(asset.assetId)


proc sound*(asset: Asset): Sound =
  ## Convert asset to a sound.
  ## Loads asset if it wasn't loaded.
  if not Sound(asset.assetId).alive:
    asset.assetId = Handle(engine.load(asset.path, Sound))
  result = Sound(asset.assetId)

proc music*(asset: Asset): Music =
  ## Convert asset to a music.
  ## Loads asset if it wasn't loaded.
  if not Music(asset.assetId).alive:
    asset.assetId = Handle(engine.load(asset.path, Music))
  result = Music(asset.assetId)