import std/json
import std/tables
import px_engine/pxd/api
import px_engine/pxd/m_math
import px_engine/pxd/m_pods
import px_engine/pxd/m_debug
import px_engine/pxd/renderer/renderer_d
import px_engine/pxd/data/m_mem_pool
import px_engine/assets/asset_texture


type SpriteAtlas* = distinct Handle
type Sprite*      = distinct Handle


type SpriteParams* = object
  name*:  string
  texId*: uint32
  texw*:  float
  texh*:  float
  sprx*:  float
  spry*:  float
  sprw*:  float
  sprh*:  float
  px*:    float
  py*:    float


type SpriteAtlasMeta = object
  app:         string
  version:     string
  image:       string
  format:      string
  size:        tuple[w,h: float]
  scale:       string
  smartupdate: string


type SpriteAtlasObj* = object
  sprite*:   OrderedTable[string, Sprite]
  meta*:     SpriteAtlasMeta
  texAsset*: Texture2D


type SpriteObj* = object
  texId*:     uint32
  texCoords*: array[4, Vec2]
  origin*:    Vec2
  size*:      Vec2
  scale*:     f32



GEN_MEM_POOL(SpriteAtlasObj, SpriteAtlas)
GEN_MEM_POOL(SpriteObj, Sprite)


#------------------------------------------------------------------------------------------
# @api sprite
#------------------------------------------------------------------------------------------
proc load*(api: EngineAPI, p: SpriteParams, typeof: typedesc[Sprite]): Sprite =
  result  = make(SpriteObj)
  let ppu = io.app.ppu
  let offsetw: f32 = p.sprx / p.texw
  let offseth: f32 = p.spry / p.texh
  let left:    f32 = offsetw
  let right:   f32 = left + p.sprw / p.texw
  let top:     f32 = 1 - offseth
  let bottom:  f32 = 1 - (offseth + p.sprh / p.texh)
  result.texId     = p.texId
  result.scale     = 1.0#ppu.f32
  result.size      = vec(p.sprw, p.sprh) / ppu
  result.origin    = vec(p.px, p.py)
  result.texcoords = [(left,bottom),(right,bottom),(right,top),(left,top)]


proc loadFontSprite*(api: EngineAPI, p: SpriteParams): Sprite =
  result  = make(SpriteObj)
  let offsetw: f32 = p.sprx / p.texw 
  let offseth: f32 = p.spry / p.texh
  let left:    f32 = offsetw
  let right:   f32 = left + p.sprw / p.texw
  let top:     f32 = 1 - offseth
  let bottom:  f32 = 1 - (offseth + p.sprh / p.texh)
  result.texId     = p.texId
  result.scale     = 1
  result.size      = vec(p.sprw, p.sprh)
  result.origin    = vec(p.px, p.py)
  result.texcoords = [(left,bottom),(right,bottom),(right,top),(left,top)]


#------------------------------------------------------------------------------------------
# @api sprite atlas
#------------------------------------------------------------------------------------------
proc onDrop*(self: SpriteAtlas) =
  for k, item in self.sprite.pairs:
    item.drop()
  self.texAsset.drop()
  self.sprite.clear()


proc load*(api: EngineAPI, path: string, typeof: typedesc[SpriteAtlas]): SpriteAtlas =
  let atlasSource = readFile(path)
  let atlasPod    = parseJson(atlasSource)
  let texture     = engine.load(io.path(atlasPod["meta"]["image"].str), true, Texture2D)
  let texture_w   = texture.get.width
  result          = make(SpriteAtlasObj)
  for k,v in atlasPod["frames"].fields.mpairs:
    var spriteParams = SpriteParams(
      name:  k,
      texId: texture.get.id,
      sprx:  v["frame"]["x"].num.float32,
      spry:  v["frame"]["y"].num.float32,
      sprw:  v["frame"]["w"].num.float32,
      sprh:  v["frame"]["h"].num.float32,
      px:    v["pivot"]["x"].fnum,
      py:    v["pivot"]["y"].fnum,
      texw:  texture.get.width.f32,
      texh:  texture.get.height.f32
    )
    result.get.sprite[k] = engine.load(spriteParams, Sprite)
  result.get.meta       = to(atlasPod["meta"], SpriteAtlasMeta)
  result.get.texAsset   = texture


proc unload*(api: EngineAPI, spriteAtlas: SpriteAtlas) =
  spriteAtlas.drop()