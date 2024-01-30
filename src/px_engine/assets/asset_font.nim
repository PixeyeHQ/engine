import px_pods
import ../px_engine_toolbox
import std/strformat
import std/strutils
import std/tables
import ../pxd/m_debug
import ../pxd/m_math
import ../pxd/m_memory
import ../pxd/m_filesystem
import ../pxd/api
import asset_texture
import asset_sprite
import asset_pack


type
  FontGlyph* = object
    sprite*: Sprite
    xadvance*: f32
    xoffset*: f32
    yoffset*: f32
  FontObj* = object
    padding*: i32
    sizeMax*: i32 # maximum allowed character height relative to the text position.
    size*: i32
    lineHeight*: i32
    texture*: Texture2D
    name*: string
    glyphs*: seq[FontGlyph]


pxd.memory.genPool(Font, FontObj)

let engine = pxd.engine
let debug = pxd.debug

#------------------------------------------------------------------------------------------
# @api font parser
#------------------------------------------------------------------------------------------
const Whitespace* = {' ', '\t', '\v', '\r', '\f'}


type FontParser = object
  step: int
  vals: Pod
  lines: seq[string]
  line: string


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
  var indexEnd = 0
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
  var indexEnd = 0
  while p.step < p.line.len:
    let c = p.line[p.step]
    case c:
      of ',', Whitespace:
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
        pod.add(initPod(parseValueString(p)))
      of PodDigits:
        pod.add(initPod(parseValueInt(p)))
      of ',':
        discard
      else:
        break
    inc p.step


proc parse(p: var FontParser, pod: var Pod) =
  var indexStart = p.step
  while p.step < p.line.len:
    var indexEnd = 0
    let c = p.line[p.step]
    case c:
      of '=':
        indexEnd = p.step - 1
        var name = p.line.substr(indexStart, indexEnd)
        pod[name] = initPodArray()
        parseValue(p, pod[name])
        skipWhitespace(p)
        indexStart = p.step
      else:
        discard
    inc p.step


proc parse(p: var FontParser, result: var Font, pixelPerfect: bool) =
  p.vals["info"] = initPodObject()
  p.vals["common"] = initPodObject()
  p.vals["page"] = initPodObject()
  p.vals["char"] = initPodObject()
  for line in p.lines:
    p.line = line
    p.step = line.find(" ") + 1
    let index = p.step - 2
    case line.substr(0, index):
      of "info":
        parse(p, p.vals["info"])
        let p1 = p.vals["info"]["padding"][0].vint.int32
        result.get.name = p.vals["info"]["face"][0].vstring
        result.get.padding = p1
      of "common":
        parse(p, p.vals["common"])
        result.sizeMax = p.vals["common"]["base"][0].vint.int32
        result.size    = i32(result.sizeMax.float * 0.25)
        result.lineHeight = p.vals["common"]["lineHeight"][0].vint.int32
        let pages = p.vals["common"]["pages"][0].vint
        if pages > 1:
          pxd.debug.fatal("BMF: format supports one page at the moment.")
      of "page":
        parse(p, p.vals["page"])
        let fileName = p.vals["page"]["file"][0].vstring
        result.texture = pxd.assets.load(&"./fonts/{fileName}", Texture2D, Texture2D_Params(
            pixelPerfect: pixelPerfect))
      of "char":
        var id, x, y, width, height, xoffset, yoffset, xadvance = 0
        parse(p, p.vals["char"])
        id = p.vals["char"]["id"][0].vint
        x = p.vals["char"]["x"][0].vint
        y = p.vals["char"]["y"][0].vint
        width = p.vals["char"]["width"][0].vint
        height = p.vals["char"]["height"][0].vint
        xoffset = p.vals["char"]["xoffset"][0].vint
        yoffset = p.vals["char"]["yoffset"][0].vint
        xadvance = p.vals["char"]["xadvance"][0].vint
        result.glyphs.grow(id):
          var c: FontGlyph
          var sp: SpriteParams
         # c.sprite = make(Sprite)
          c.xoffset = xoffset.float
          c.yoffset = yoffset.float
          c.xadvance = xadvance.float
        #  sp.texId = result.get.texture.get.id
          sp.sprx = x.float
          sp.spry = y.float
          sp.sprw = width.float
          sp.sprh = height.float
         # sp.texw = result.get.texture.get.width.float
        #  sp.texh = result.get.texture.get.height.float
          c.sprite = pxd.assets.loadFontSprite(result.get.texture, sp)
          result.glyphs[id] = c
      of "kerning":
        var first, second, amount = 0
        parse(p, p.vals["kerning"])
        first = p.vals["kerning"]["first"][0].vint
        second = p.vals["kerning"]["second"][0].vint
        amount = p.vals["kerning"]["amount"][0].vint
      else:
        discard


proc load*(api: AssetAPI, relativePath: string, pixelPerfect: bool, typeof: typedesc[Font]): Font =
  result = make(Font)
  let fontSource = readFile(pxd.filesystem.path(relativePath))
  var parser = FontParser()
  parser.lines = fontSource.split('\n')
  parser.vals = initPodObject()
  parser.parse(result, pixelPerfect)


proc load*(pack: AssetPack, relativePath: string, pixelPerfect: bool, typeof: typedesc[Font]): Font {.discardable.} =
  var tag = relativePath & $typeof
  result = pxd.assets.load(relativePath, pixelPerfect, typeof)
  pack.items[tag] = (Handle)result
