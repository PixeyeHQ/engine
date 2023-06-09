import std/strformat
import std/strutils
import engine/px
import engine/m_io
import engine/pxd/api
import engine/pxd/m_utils_collections
import engine/pxd/m_pods
import engine/pxd/m_debug
import engine/pxd/m_math
import engine/pxd/data/m_mem_pool
import asset_texture
import asset_sprite


type Font*    = distinct Handle
type FontGlyph* = object
  sprite*:   Sprite
  xadvance*: float32
  xoffset*:  float32
  yoffset*:  float32


type FontObj* = object
  padding*:    int32
  size*:       int32 # maximum allowed character height relative to the text position.
  lineHeight*: int32
  texture*:    Texture2D
  name*:       string
  glyphs*:     seq[FontGlyph]


GEN_MEM_POOL(FontObj, Font)


#------------------------------------------------------------------------------------------
# @api font parser
#------------------------------------------------------------------------------------------
const Whitespace* = {' ', '\t', '\v', '\r', '\f'}


type FontParser = object
  step:  int
  vals:  Pod
  lines: seq[string]
  line:  string



# # proc getFontTexture(fileName: string): Texture =
# #   let path = getAppDir() & &"/assets/" & fileName
# #   result   = render.loadTexture(path)


proc skipWhitespace(p: var FontParser) =
  while p.step < p.line.len:
    let c = p.line[p.step]
    if c in Whitespace:
      inc p.step
    else:
      break


proc parseValueString(p: var FontParser): string =
  inc p.step
  var indexStart = p.step
  var indexEnd   = 0
  while p.step < p.line.len:
    let c = p.line[p.step]
    case c:
      of '"':
        indexEnd = p.step - 1
        break
      else:
        discard
    inc p.step
  result = p.line.substr(indexStart, indexEnd)


proc parseValueInt(p: var FontParser): int =
  var indexStart = p.step
  var indexEnd   = 0
  while p.step < p.line.len:
    let c = p.line[p.step]
    case c:
      of ',',Whitespace:
        indexEnd = p.step - 1
        break
      else:
        discard
    inc p.step
  result = parseInt(p.line.substr(indexStart, indexEnd))


proc parseValue(p: var FontParser, pod: var Pod) =
  inc p.step
  while p.step < p.line.len:
    let c = p.line[p.step]
    case c:
      of '"':
        pod.add(pxd.pods.initPod(parseValueString(p)))
      of PodDigits:
        pod.add(pxd.pods.initPod(parseValueInt(p)))
      of ',':
        discard
      else:
        break
    inc p.step


proc parse(p: var FontParser, pod: var Pod) =
      var indexStart = p.step
      while p.step < p.line.len:
        var indexEnd   = 0
        let c = p.line[p.step]
        case c:
          of '=':
            indexEnd  = p.step - 1
            var name = p.line.substr(indexStart, indexEnd)
            pod[name] = pxd.pods.initPodArray()
            parseValue(p,pod[name])
            skipWhitespace(p)
            indexStart = p.step
          else:
            discard
        inc p.step


proc parse(p: var FontParser, result: var Font) =
  p.vals["info"]   = pxd.pods.initPodObject()
  p.vals["common"] = pxd.pods.initPodObject()
  p.vals["page"]   = pxd.pods.initPodObject()
  p.vals["char"]   = pxd.pods.initPodObject()
  for line in p.lines:
    p.line    = line
    p.step    = line.find(" ") + 1
    let index = p.step - 2
    case line.substr(0, index):
      of "info":
        parse(p,p.vals["info"])
        let p1 = p.vals["info"]["padding"][0].vint.int32
        result.get.name    = p.vals["info"]["face"][0].vstring
        result.get.padding = p1
      of "common":
        parse(p,p.vals["common"])
        result.size       = p.vals["common"]["base"][0].vint.int32
        result.lineHeight = p.vals["common"]["lineHeight"][0].vint.int32
        let pages         = p.vals["common"]["pages"][0].vint
        if pages > 1:
          debug.fatal("BMF", "format supports one page at the moment.")
      of "page":
        parse(p,p.vals["page"])
        let fileName = p.vals["page"]["file"][0].vstring
        var pixelPerfect = if result.get.name == "ProggyCleanTT": true else: false
        result.texture = engine.load(io.path(&"./assets/fonts/{fileName}"), pixelPerfect, Texture2D)
      of "char":
        var id, x, y, width, height, xoffset, yoffset, xadvance = 0
        parse(p,p.vals["char"])
        id       = p.vals["char"]["id"][0].vint
        x        = p.vals["char"]["x"][0].vint
        y        = p.vals["char"]["y"][0].vint
        width    = p.vals["char"]["width"][0].vint
        height   = p.vals["char"]["height"][0].vint
        xoffset  = p.vals["char"]["xoffset"][0].vint
        yoffset  = p.vals["char"]["yoffset"][0].vint
        xadvance = p.vals["char"]["xadvance"][0].vint
        result.glyphs.grow(id):
          var c: FontGlyph
          var sp: SpriteParams
          c.sprite = make(SpriteObj)
          c.xoffset  = xoffset.float
          c.yoffset  = yoffset.float
          c.xadvance = xadvance.float
          sp.texId = result.get.texture.get.id
          sp.sprx  = x.float
          sp.spry  = y.float
          sp.sprw  = width.float
          sp.sprh  = height.float
          sp.texw  = result.get.texture.get.width.float
          sp.texh  = result.get.texture.get.height.float
          c.sprite = engine.loadFontSprite(sp)
          result.glyphs[id] = c
      of "kerning":
        var first, second, amount = 0
        parse(p,p.vals["kerning"])
        first  = p.vals["kerning"]["first"][0].vint
        second = p.vals["kerning"]["second"][0].vint
        amount = p.vals["kerning"]["amount"][0].vint
      else:
        discard


proc load*(api: EngineAPI, path: string, typeof: typedesc[Font]): Font =
  result = make(FontObj)
  let fontSource = readFile(path)
  var parser     = FontParser()
  parser.lines   = fontSource.split('\n')
  parser.vals    = pxd.pods.initPodObject()
  parser.parse(result)

