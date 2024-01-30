import px_pods
import std/json
import std/tables
import std/strformat
import std/strutils
import ../pxd/m_debug
import ../pxd/m_math
import ../pxd/m_memory
import ../pxd/m_filesystem
import ../pxd/m_vars
import ../pxd/api
import ../assets/asset_texture
import ../assets/asset_pack

type
  Sprite* = distinct Handle
  SpriteAtlasParams* = object
    border*: int
    absoluteX*: int = -1
    absoluteY*: int = -1
    normalizedX*: float
    normalizedY*: float
    msPerFrame*: int = 100
  SpriteParams* = object
    name*: string
    sprx*: float
    spry*: float
    sprw*: float
    sprh*: float
    px*: float
    py*: float
    offsetY*: float
    offsetX*: float
  SpriteAtlasMeta = object
    app: string
    version: string
    image: string
    format: string
    size: tuple[w, h: float]
    scale: string
    smartupdate: string
  SpriteAtlasObj* = object
    sprite*: OrderedTable[string, Sprite]
    sprites*: seq[Sprite]
    meta*: SpriteAtlasMeta
    texture*: Texture2D
  SpriteObj* = object
    texId*: uint32
    texCoords*: array[4, Vec2]
    origin*: Vec2
    worldSize*: Vec2
    worldOffsetX*: f32
    worldOffsetY*: f32
    scale*:   f32
  SpriteSequence* = object
    items*: seq[Sprite]
  SpriteSequences* = object
    items*: Table[int, SpriteSequence]


proc len*(self: var SpriteSequence): int = self.items.len


proc `[]`*(self: var SpriteSequence, index: int): Sprite =
  self.items[index]


proc `[]`*(self: var SpriteSequences, index: int): var SpriteSequence =
  self.items[index]


proc `[]=`*(self: var SpriteSequences, index: int, element: SpriteSequence) =
  self.items[index] = element



pxd.memory.genPoolTyped(Sprite, SpriteObj)
pxd.memory.genPool(SpriteAtlas, SpriteAtlasObj)


let runtime_ppu = pxd.vars.get("runtime.ppu", float)
 #------------------------------------------------------------------------------------------
 # @api sprite
 #------------------------------------------------------------------------------------------
proc load(texture: Texture2D, params: SpriteParams): Sprite =
  result = make(Sprite)
  let texw = texture.get.width.float
  let texh = texture.get.height.float
  let offsetw: f32 = params.sprx / texw
  let offseth: f32 = params.spry / texh
  var left:  f32   = offsetw
  var right: f32   = left + params.sprw / texw
  let top: f32     = 1 - offseth
  let bottom: f32  = 1 - (offseth + params.sprh / texh)
  result.texId     = texture.get.id
  result.scale     = 1
  result.worldSize = vec(params.sprw, params.sprh) / runtime_ppu[]
  result.origin    = vec(params.px, params.py)
  result.texcoords = [(left, bottom), (right, bottom), (right, top), (left, top)]


proc load*(pack: AssetPack, relativePath: string, typeof: typedesc[Sprite],
    params: SpriteParams): Sprite {.discardable.} =
  var tag = relativePath & $typeof
  if not pack.has(relativePath, Texture2D):
    pack.load(relativePath, Texture2D)
  result = load(pack.get(relativePath, Texture2D), params)
  pack.items[tag] = (Handle)result


proc load*(pack: AssetPack, relativePath: string, typeof: typedesc[Sprite]): Sprite {.discardable.} =
  pack.load(relativePath, typeof, SpriteParams())


proc load*(api: AssetAPI, p: SpriteParams, typeof: typedesc[Sprite]): Sprite =
  result = make(Sprite)
  let ppu = runtime_ppu[]
  let offsetw: f32 = p.sprx / p.texw
  let offseth: f32 = p.spry / p.texh
  var left: f32 = offsetw
  var right: f32 = left + p.sprw / p.texw
  let top: f32 = 1 - offseth
  let bottom: f32 = 1 - (offseth + p.sprh / p.texh)
  result.texId = p.texId
  result.scale = ppu.f32
  result.worldSize = vec(p.sprw, p.sprh) / ppu
  result.origin = vec(p.px, p.py)
  result.texcoords = [(left, bottom), (right, bottom), (right, top), (left, top)]


proc loadAseprite*(api: EngineAPI, t: Texture2D, p: SpriteParams): Sprite =
  result = make(Sprite)
  let ppu = runtime_ppu[]
  let offsetw: f32 = p.sprx / t.width.float
  let offseth: f32 = p.spry / t.height.float
  var left: f32 = offsetw
  var right: f32 = left + p.sprw / t.width.float
  var top: f32 = offseth + p.sprh / t.height.float
  var bottom: f32 = offseth
  result.texId = t.get.id
  result.scale = 1.0
  result.worldSize = vec(p.sprw, p.sprh) / ppu
  result.origin    = vec(p.px, p.py)
  result.texcoords = [(left, top), (right, top), (right, bottom), (left, bottom)]
  result.worldOffsetX = p.offsetX
  result.worldOffsetY = p.offsetY


proc loadFontSprite*(api: AssetAPI, t: Texture2D, p: SpriteParams): Sprite =
  result = make(Sprite)
  let offsetw: f32 = p.sprx / t.width.float
  let offseth: f32 = p.spry / t.height.float
  let left: f32 = offsetw
  let right: f32 = left + p.sprw / t.width.float
  let top: f32 = 1 - offseth
  let bottom: f32 = 1 - (offseth + p.sprh / t.height.float)
  result.texId = t.get.id
  result.scale = 1
  result.worldSize = vec(p.sprw, p.sprh)
  result.origin = vec(0.5, 0.5)
  result.texcoords = [(left, bottom), (right, bottom), (right, top), (left, top)]


#------------------------------------------------------------------------------------------
# @api sprite atlas
#------------------------------------------------------------------------------------------
proc onDrop*(self: SpriteAtlas) =
  for k, item in self.sprite.pairs:
    item.drop()
  self.texture.drop()
  self.sprite.clear()


proc load(api: AssetAPI, relativePath: string, typeof: typedesc[SpriteAtlas]): SpriteAtlas =
  result = make(SpriteAtlas)
  let path = pxd.filesystem.path(relativePath)
  let atlasSource = readFile(path)
  let atlasPod = parseJson(atlasSource)
  let texture = pxd.assets.load("./images/atlases/" & atlasPod["meta"]["image"].str, Texture2D, Texture2D_Params())
  var spriteParams: SpriteParams
  for v in atlasPod["frames"].items:
    spriteParams = SpriteParams(
      name: v["filename"].getStr(),
      sprx: v["frame"]["x"].getFloat(),
      spry: v["frame"]["y"].getFloat(),
      sprw: v["frame"]["w"].getFloat(),
      sprh: v["frame"]["h"].getFloat(),
      px: 1.0-v["pivot"]["x"].getFloat(),
      py: 1.0-v["pivot"]["y"].getFloat()
    )
    var nsprite = load(texture, spriteParams)
    result.get.sprite[spriteParams.name] = nsprite
    result.get.sprites.add(nsprite)
  result.get.texture = texture
  result.get.meta    = to(atlasPod["meta"], SpriteAtlasMeta)


proc unload*(api: AssetAPI, spriteAtlas: SpriteAtlas) =
  spriteAtlas.drop()


proc load*(pack: AssetPack, relativePath: string, typeof: typedesc[SpriteAtlas]): SpriteAtlas {.discardable.} =
  let tag = relativePath & $typeof
  result = pxd.assets.load(relativePath, SpriteAtlas)
  pack.items[tag] = (Handle)result


proc get*(pack: AssetPack, relativePath: string, typeof: typedesc[SpriteAtlas]): SpriteAtlas {.discardable.} =
  let tag = relativePath & $typeof
  if not pack.has(relativePath, SpriteAtlas):
    pxd.debug.error("ASSETS: Sprite Atlas is not found!")
  (SpriteAtlas)pack.items[tag]

proc getSprites*(atlas: SpriteAtlas, fromSprite: string, command: string): SpriteSequence =
  var s     = atlas.get.sprite[fromSprite]
  var index = find(atlas.get.sprites, s)
  if command.contains(".."):
    var times = 1
    var vfrom = 0
    var vto   = 0
    if command.contains(";"):
      var tokens1 = command.split(";")
      var tokens2 = tokens1[0].split("..")
      times = tokens1[1].parseInt()
      vfrom = tokens2[0].parseInt()
      vto   = tokens2[1].parseInt()
    else:
      var tokens = command.split("..")
      vfrom = tokens[0].parseInt()
      vto   = tokens[1].parseInt()
    for next in vfrom..vto:
      for _ in 0..<times:
        result.items.add(atlas.sprites[next])
  else:
    var tokens = command.split(',')
    for ntoken in tokens:
      var vtoken = ntoken.parseInt()
      result.items.add(atlas.sprites[vtoken])