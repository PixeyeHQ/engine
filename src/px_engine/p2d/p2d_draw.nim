import std/unicode
import px_engine/Px
import px_engine/m_pxd
import px_engine/m_assets
import api



var render2D     = engine.render2D

# Indices: A,B,C,C,D,A or 0,1,2,2,3,0
# D----YT---C
# |    |    |
# XL---+---XR
# |    |    |
# A----YB---B


#------------------------------------------------------------------------------------------
# @api pixel
#------------------------------------------------------------------------------------------
proc pixel*(api: P2DrawAPI, x,y,z: f32; size: f32; color: Color) =
  const indices = 0
  render2D.setType(R2D_GEOMETRY)
  r2d.draw(render2D.renderer, indices):
    r2d.color(color)
    r2d.vertex(x     ,y     ,z) #A:0
    r2d.vertex(x+size,y     ,z) #B:1
    r2d.vertex(x+size,y+size,z) #C:2
    r2d.vertex(x     ,y+size,z) #D:3
    r2d.vertex(x     ,y     ,z) #A:0
    r2d.vertex(x+size,y+size,z) #C:2


proc pixel*(api: P2DrawAPI, x,y: f32; size: f32; color: Color) =
  const z = 0
  api.pixel(x,y,z,size,color)


proc pixel*(api: P2DrawAPI, pos: Vec3; size: f32; color: Color) =
  api.pixel(pos.x,pos.y,pos.z,size,color)


#------------------------------------------------------------------------------------------
# @api rectangle
#------------------------------------------------------------------------------------------
proc rect*(api: P2DrawAPI, x,y,z: f32; w,h: f32; color: Color) =
  ## Draw a rectangle.
  ## Renderer: ShapeRender.
  const indices = 0
  render2D.setType(R2D_GEOMETRY)
  r2d.draw(render2D.renderer, indices):
    r2d.color(color)
    r2d.texture(render2D.texWhite.get.id)
    r2d.vertex(x  ,y  ,z) #A:0
    r2d.vertex(x+w,y  ,z) #B:1
    r2d.vertex(x+w,y+h,z) #C:2
    r2d.vertex(x  ,y+h,z) #D:3
    r2d.vertex(x  ,y  ,z) #A:0
    r2d.vertex(x+w,y+h,z) #C:2


proc rect*(api: P2DrawAPI, x,y: f32; w,h: f32; color: Color) {.inline.} =
  const z = 0
  api.rect(x,y,z,w,h,color)


proc rect*(api: P2DrawAPI, pos: Vec3; size: Vec2; color: Color) {.inline.}=
  ## Draw a rectangle.
  api.rect(pos.x,pos.y,pos.z,size.w,size.h,color)


#------------------------------------------------------------------------------------------
# @api texture
#------------------------------------------------------------------------------------------
proc texture*(api: P2DrawAPI, texture: Texture2D, pos: Vec3, origin: Vec2 = vec2(0.5,0.5), scale: f32 = 1.0, color: Color = cWhite) =
  const indices = 6
  render2D.setType(R2D_SPRITE)
  let texture   = texture.get.addr
  let w         = texture.width.f32  * scale
  let h         = texture.height.f32 * scale
  let x         = pos.x - w * origin.x
  let y         = pos.y - h * origin.y
  r2d.draw(render2D.renderer, indices):
    r2d.texture(texture.id)
    r2d.color(color)
    r2d.vertex(x,  y,  pos.z,0f,0f) #A:0
    r2d.vertex(x+w,y,  pos.z,1f,0f) #B:1
    r2d.vertex(x+w,y+h,pos.z,1f,1f) #C:2
    r2d.vertex(x  ,y+h,pos.z,0f,1f) #D:3


proc texture*(api: P2DrawAPI, texture: Texture2D, pos: Vec3, origin: Vec2 = vec2(0.5,0.5), rotation: f32 = 0.0, scale: f32 = 1.0, color: Color = cWhite) =
  # origin is normalized
  # xx,yy: local position
  const indices = 6
  render2D.setType(R2D_SPRITE)
  let texture   = texture.get.addr
  if rotation == 0:
    let w         = texture.width.f32  * scale
    let h         = texture.height.f32 * scale
    let x         = pos.x - w * origin.x
    let y         = pos.y - h * origin.y
    r2d.draw(render2D.renderer, indices):
      r2d.texture(texture.id)
      r2d.color(color)
      r2d.vertex(x,  y,  pos.z, 0.0, 0.0) #A:0
      r2d.vertex(x+w,y,  pos.z, 1.0, 0.0) #B:1
      r2d.vertex(x+w,y+h,pos.z, 1.0, 1.0) #C:2
      r2d.vertex(x  ,y+h,pos.z, 0.0, 1.0) #D:3
  else:
    let sinRotation = sin(rotation*DEG2RAD)
    let cosRotation = cos(rotation*DEG2RAD)
    let w      = texture.width.f32  * scale
    let h      = texture.height.f32 * scale
    var xx     = -(w * origin.x)
    var yy     = -(h * origin.y)
    template vx(index: int): untyped {.dirty.} =
      when index == 0:
        pos.x + (xx*cosRotation)     + (yy*sinRotation)
      elif index == 1:
        pos.x + ((xx+w)*cosRotation) + (yy*sinRotation)
      elif index == 2:
        pos.x + ((xx+w)*cosRotation) + ((yy+h)*sinRotation)
      elif index == 3:
        pos.x + (xx*cosRotation)     + ((yy+h)*sinRotation)
      else:
        debug.fatal("Draw","ERROR")
        0.0
    template vy(index: int): untyped {.dirty.} =
      when index == 0:
        pos.y - (xx*sinRotation)     + (yy*cosRotation)
      elif index == 1:
        pos.y - ((xx+w)*sinRotation) + (yy*cosRotation)
      elif index == 2:
        pos.y - ((xx+w)*sinRotation) + ((yy+h)*cosRotation)
      elif index == 3:
        pos.y - (xx*sinRotation)     + ((yy+h)*cosRotation)
      else:
        debug.fatal("Draw","ERROR")
        0.0
    r2d.draw(render2D.renderer, indices):
      r2d.texture(texture.id)
      r2d.color(color)
      r2d.vertex(vx(0), vy(0), pos.z, 0.0, 0.0) #A:0
      r2d.vertex(vx(1), vy(1), pos.z, 1.0, 0.0) #B:1
      r2d.vertex(vx(2), vy(2), pos.z, 1.0, 1.0) #C:2
      r2d.vertex(vx(3), vy(3), pos.z, 0.0, 1.0) #D:3


#------------------------------------------------------------------------------------------
# @api sprite
#------------------------------------------------------------------------------------------
template inline_draw_sprite(renderer: Renderer2D) {.dirty.} =
  let w         = sprite.size.w * scale
  let h         = sprite.size.h * scale
  let x         = pos.x - w * sprite.origin.x
  let y         = pos.y - h * sprite.origin.y
  r2d.draw(renderer, indices):
    r2d.texture(sprite.texId)
    r2d.color(color)
    r2d.vertex(x,  y,  pos.z,sprite.texCoords[0]) #A:0
    r2d.vertex(x+w,y,  pos.z,sprite.texCoords[1]) #B:1
    r2d.vertex(x+w,y+h,pos.z,sprite.texCoords[2]) #C:2
    r2d.vertex(x  ,y+h,pos.z,sprite.texCoords[3]) #D:3


proc sprite*(api: P2DrawAPI, sprite: Sprite, pos: Vec3, scale: f32 = 1.0, color: Color = cWhite) {.inline.} =
  const indices = 6
  render2D.setType(R2D_SPRITE)
  let sprite    = sprite.get.addr
  inline_draw_sprite(render2D.renderer)


proc sprite*(api: P2DrawAPI, sprite: Sprite, pos: Vec3, rotation: f32 = 0.0, scale: f32 = 1.0, color: Color = cWhite) {.inline.} =
  # origin is normalized
  # xx,yy: local position
  const indices = 6
  render2D.setType(R2D_SPRITE)
  let sprite   = sprite.get.addr
  if rotation == 0:
    inline_draw_sprite(render2D.renderer)
  else:
    let sinRotation = sin(rotation*DEG2RAD)
    let cosRotation = cos(rotation*DEG2RAD)
    let w      = sprite.size.w * scale
    let h      = sprite.size.h * scale
    var xx     = -(w * sprite.origin.x)
    var yy     = -(h * sprite.origin.y)
    template vx(index: int): untyped {.dirty.} =
      when index == 0:
        pos.x + (xx*cosRotation)     + (yy*sinRotation)
      elif index == 1:
        pos.x + ((xx+w)*cosRotation) + (yy*sinRotation)
      elif index == 2:
        pos.x + ((xx+w)*cosRotation) + ((yy+h)*sinRotation)
      elif index == 3:
        pos.x + (xx*cosRotation)     + ((yy+h)*sinRotation)
      else:
        debug.fatal("Draw","ERROR")
        0.0
    template vy(index: int): untyped {.dirty.} =
      when index == 0:
        pos.y - (xx*sinRotation)     + (yy*cosRotation)
      elif index == 1:
        pos.y - ((xx+w)*sinRotation) + (yy*cosRotation)
      elif index == 2:
        pos.y - ((xx+w)*sinRotation) + ((yy+h)*cosRotation)
      elif index == 3:
        pos.y - (xx*sinRotation)     + ((yy+h)*cosRotation)
      else:
        debug.fatal("Draw","ERROR")
        0.0
    r2d.draw(render2D.renderer, indices):
      r2d.texture(sprite.texId)
      r2d.color(color)
      r2d.vertex(vx(0), vy(0), pos.z, sprite.texCoords[0]) #A:0
      r2d.vertex(vx(1), vy(1), pos.z, sprite.texCoords[1]) #B:1
      r2d.vertex(vx(2), vy(2), pos.z, sprite.texCoords[2]) #C:2
      r2d.vertex(vx(3), vy(3), pos.z, sprite.texCoords[3]) #D:3


#------------------------------------------------------------------------------------------
# @api font
#------------------------------------------------------------------------------------------
const SomeWhitespace = [" ", "\t", "\v", "\r", "\l", "\f"]


template cursorStep(): float {.dirty.} =
  (glyph.xadvance - fontPadding * 2) * textScale


template lineStep(): float {.dirty.} =
  (font.lineHeight.float + render2D.get.textLineSpacing) * textScale


template peekWordWidth(parseIndex: int): float {.dirty.} =
  var peekSize = 0.0
  block:
    var peekIndex = parseIndex
    while peekIndex < text.len:
      let rune    = text[peekIndex].Rune
      let runeUTF = rune.toUTF8()
      var glyph   = font.get.glyphs[int(rune)]
      case runeUTF:
        of SomeWhitespace:
          peekSize += cursorStep()
          break
        else:
          peekSize += cursorStep()
      inc peekIndex
  peekSize


template drawGlyph(glyph: var FontGlyph, pos: Vec3, scale: float = 1.0, color: Color = cWhite)  =
  const indices = 6
  let sprite    = glyph.sprite.get.addr
  let w = sprite.size.w * scale
  let h = sprite.size.h * scale
  let x = pos.x + glyph.xoffset * scale
  var y = pos.y - glyph.yoffset * scale - h
  r2d.draw(render2D.renderer, indices):
    r2d.texture(sprite.texId)
    r2d.color(color)
    r2d.vertex(x,  y,  pos.z,sprite.texCoords[0]) #A:0
    r2d.vertex(x+w,y,  pos.z,sprite.texCoords[1]) #B:1
    r2d.vertex(x+w,y+h,pos.z,sprite.texCoords[2]) #C:2
    r2d.vertex(x  ,y+h,pos.z,sprite.texCoords[3]) #D:3


template textDraw() {.dirty.} =
  let rune    = text[parseIndex[]].Rune
  let runeUTF = rune.toUTF8()
  var glyph   = font.get.glyphs[int(rune)]
  case runeUTF:
    of "\n":
      cursor.y -= lineStep()
      cursor.x = pos.x
      inc parseIndex[]
      continue
    of " ":
      cursor.x += cursorStep()
      inc parseIndex[]
      continue
    else:
      drawGlyph(glyph, cursor, textScale, color)
      cursor.x += cursorStep()
  inc parseIndex[]


template textAlignBounds() {.dirty.} =
  var peekTextWidth = cursor.x + peekWordWidth(parseIndex[])
  if textBounds.x < peekTextWidth:
     cursor.y -= lineStep()
     cursor.x  = pos.x


proc text*(api: P2DrawAPI, text: string, pos: Vec3, textScale: f32 = 1.0, color: Color = cWhite) {.inline.} =
  render2D.setType(R2D_FONT)
  render2D.renderer.useShader(render2d.get.fontShader):
    let parseIndex  = render2D.get.textParseIndex.addr
    let textBounds  = render2D.get.textBounds
    let font        = render2D.get.font
    let fontPadding = font.get.padding.float
    let fontSize    = font.get.size.float
    var cursor      = pos
    parseIndex[]    = 0
    if textBounds == vec2_default:
      # DRAW DEFAULT
      while parseIndex[] < text.len:
        textDraw()
    else: 
      # DRAW BOUNDEDED
      while parseIndex[] < text.len:
        textAlignBounds()
        textDraw()


proc text*(api: P2DrawAPI, text: string, x: f32, y: f32, z: f32, textScale: f32 = 1.0, color: Color = cWhite) {.inline.} =
  text(api, text, vec(x,y,z), textScale, color)


proc text*(api: P2DrawAPI, text: string, x: f32, y: f32, textScale: f32 = 1.0, color: Color = cWhite) {.inline.} =
  text(api, text, vec(x,y,0.0), textScale, color)


proc setFont*(api: P2DrawAPI, font: Font) =
  render2D.get.font = font


proc setTextLineSpacing*(api: P2DrawAPI, value: float) =
  render2D.get.textLineSpacing = value


proc resetFont*(api: P2DrawAPI) =
  render2D.get.font = render2D.get.fontDefault


template bounds*(api: P2DrawAPI, width: float, code: untyped) =
  render2D.get.textBounds = vec2(width, 0)
  code
  render2D.get.textBounds = vec2(0, 0)
