## ASE files use Intel (little-endian) byte order
## ASE files specs: https://github.com/aseprite/aseprite/blob/main/docs/ase-file-specs.md


import px_pods
import ../px_engine_toolbox
import std/json
import std/tables
import std/streams
import std/strutils
import ../pxd/m_debug
import ../pxd/m_math
import ../pxd/m_memory
import ../pxd/m_vars
import ../pxd/m_key
import ../pxd/api
import asset_texture
import asset_sprite
import asset_pack
#import nimBMP

# WORD        Number of tags
# BYTE[8]     For future (set to zero)
# + For each tag
#   WORD      From frame
#   WORD      To frame
#   BYTE      Loop animation direction
#               0 = Forward
#               1 = Reverse
#               2 = Ping-pong
#               3 = Ping-pong Reverse
#   WORD      Repeat N times. Play this animation section N times:
#               0 = Doesn't specify (plays infinite in UI, once on export,
#                   for ping-pong it plays once in each direction)
#               1 = Plays once (for ping-pong, it plays just in one direction)
#               2 = Plays twice (for ping-pong, it plays once in one direction,
#                   and once in reverse)
#               n = Plays N times
#   BYTE[6]   For future (set to zero)
#   BYTE[3]   RGB values of the tag color
#               Deprecated, used only for backward compatibility with Aseprite v1.2.x
#               The color of the tag is the one in the user data field following
#               the tags chunk
#   BYTE      Extra byte (zero)
#   STRING    Tag name


type
  TempImage = object
    data: seq[byte]
    width: int
    height: int
  AsepriteHeader = object
    frames: int
    width: int
    height: int
    colorDepth: int # 32,24,8 bits need to be converted in channels when used to receive pixels
  AsepriteFrameHeader = object
    frameSize: int
    frameDuration: int
    chunks: int
  AsepriteLayer = object
    name: string
    userData: string
  AsepriteCel = object
    layerIndex: int
    positionX: int
    positionY: int
    opacityLevel: int
    celType: int
    celData: seq[byte]
    indexZ: int
    width: int
    height: int
    pivotX: float = float.high
    pivotY: float = float.high
  AsepriteTag = object
    frameFrom: int
    frameTo: int
    animDirection: int
    repeatTimes: int
    name: string
  AsepriteChunk = object
    chunkSize: int
    chunkType: int
    chunkData: seq[byte]
  AsepriteChunkUserData = object
    chunkName: string
    chunkType: int
    chunkData: string
  AsepriteFrame = object
    header: AsepriteFrameHeader
    chunks: seq[AsepriteChunk]
    cel: AsepriteCel
  AsepriteObj* = object
    header: AsepriteHeader
    layers: seq[AsepriteLayer]
    frames: seq[AsepriteFrame]
    tags: seq[AsepriteTag]
  AsepriteState = object
    pivotX: float = float.high
    pivotY: float = float.high
    chunk:   pointer 
    chunkType: int

pxd.memory.genPool(Aseprite, AsepriteObj)
var state: AsepriteState = AsepriteState(pivotX: float.high, pivotY: float.high)
let runtime_ppu = pxd.vars.get("runtime.ppu", float)

proc readAsepriteHeader(self: Aseprite, s: Stream) =
  discard readU32LE(s) # fileSize
  discard readU16LE(s) # magicNumber
  self.header.frames = readU16LE(s).int
  self.header.width = readU16LE(s).int
  self.header.height = readU16LE(s).int
  self.header.colorDepth = readU16LE(s).int
  discard readU32LE(s)   # flags
  discard readU16LE(s)   # speed
  discard readStr(s, 8)  # ignore 8 bytes
  discard readChar(s)    # paletteEntry
  discard readStr(s, 3)  # ignore 3 bytes
  discard readU16LE(s)   # numColors
  discard readChar(s)    # pixelWidth
  discard readChar(s)    # pixelHeight
  discard readU16LE(s)   # gridX
  discard readU16LE(s)   # gridY
  discard readU16LE(s)   # gridWidth
  discard readU16LE(s)   # gridHeight
  discard readStr(s, 84) # ignore 84 bytes


proc readAsepriteChunkHeader(frame: var AsepriteFrame, s: Stream) =
  var chunks, chunksNew = 0
  var frameSize = 0
  var frameDuration = 0
  frameSize = readU32LE(s).int
  discard readU16LE(s) # magicNumber
  chunks = readU16LE(s).int
  frameDuration = readU16LE(s).int
  discard readStr(s, 2)
  chunksNew = readU32LE(s).int
  frame.header.frameSize = frameSize
  frame.header.frameDuration = frameDuration
  frame.header.chunks = if chunksNew == 0: chunks else: chunksNew


proc readAsepriteFrameChunk(self: var AsepriteChunk, s: Stream) =
  self.chunkSize = readU32LE(s).int
  self.chunkType = readU16LE(s).int
  for _ in 0 ..< self.chunkSize - 6:
    self.chunkData.add(readChar(s).byte)


proc readCompressedImage(aseprite: Aseprite, frame: var AsepriteFrame, chunk: var AsepriteChunk, s: var StringStream) =
  let channelsCount = aseprite.header.colorDepth div 8 # 4,2,1 channels in aseprite
  frame.cel.width  = readU16LE(s).int
  frame.cel.height = readU16LE(s).int
  let w = frame.cel.width
  let h = frame.cel.height
  let pixelsCount = w * h * channelsCount
  var rawPixelData = newSeq[byte](chunk.chunkData.len)
  for index in 0 ..< rawPixelData.len:
    rawPixelData[index] = readChar(s).byte
  var decompressedPixelData = decompressZlibBytes(rawPixelData)
  frame.cel.celData = newSeq[byte](pixelsCount)
  for i in 0 ..< decompressedPixelData.len div channelsCount:
    let index = i * channelsCount
    # when using Opengl we need to flip pixels vertically or image will be upside down
    # revisit: you don't neet to flip pixels on this step.
    # let destIndex = ((h - 1) - (i div w)) * w * channelsCount + ((i mod w)) * channelsCount
    for c in 0..<channelsCount:
      frame.cel.celData[index + c] = decompressedPixelData[index + c]


proc readAsepriteUserData(aseprite: Aseprite, frame: var AsepriteFrame, chunk: var AsepriteChunk) =
  # reads pixel data of each image in aseprite frame.
  if chunk.chunkType != 0x2020: return
  var s = newStringStream(chunk.chunkData.toString())
  var pivot = (x:float.high,y:float.high)
  var flag = readU32LE(s).int
  if flag == 1:
    var userData = readStr(s, readU16LE(s).int).trim(' ')
    var elements = userData.split(';');
    for elem in elements.items:
      var tokens = elem.split(':')
      if tokens[0] == "px":
        pivot.x = parseInt(tokens[1]).float
      elif tokens[0] == "py":
        pivot.y = parseInt(tokens[1]).float
    if state.chunkType == 0x2004:
      if state.pivotX == float.high and state.pivotY == float.high:
        state.pivotX = pivot.x.float
        state.pivotY = pivot.y.float
    elif state.chunkType == 0x2005:
      let cel = cast[ptr AsepriteCel](state.chunk)
      cel.pivotX = pivot.x.float
      cel.pivotY = pivot.y.float


proc readAsepriteLayer(aseprite: Aseprite, frame: var AsepriteFrame, chunk: var AsepriteChunk) =
  # reads pixel data of each image in aseprite frame.
  if chunk.chunkType != 0x2004: return
  var s = newStringStream(chunk.chunkData.toString())
  var layerFlag = readU16LE(s).int
  var layerType = readU16LE(s).int
  var layerChildLevel = readU16LE(s).int
  var layerW = readU16LE(s).int
  var layerH = readU16LE(s).int
  var layerBlendmode = readU16LE(s).int
  var layerOpacity = readUint8(s).int
  discard readStr(s, 3) # Deprecated, RGB values of the tag color
  var layerName = readStr(s, readU16LE(s).int)
  if layerType == 2:
    discard readU32LE(s).int
  aseprite.get.layers.add(AsepriteLayer(name: layerName))
  state.chunkType = chunk.chunkType
  state.chunk     = cast[pointer](aseprite.get.layers[aseprite.get.layers.high].addr)


proc readAsepriteFrameCel(aseprite: Aseprite, frame: var AsepriteFrame, chunk: var AsepriteChunk) =
  # reads pixel data of each image in aseprite frame.
  if chunk.chunkType != 0x2005: return
  var s = newStringStream(chunk.chunkData.toString())
  frame.cel.layerIndex = readU16LE(s).int
  frame.cel.positionX = readU16LE(s).int
  frame.cel.positionY = readU16LE(s).int
  frame.cel.opacityLevel = readChar(s).int
  frame.cel.celType = readU16LE(s).int
  frame.cel.indexZ = readU16LE(s).int
  discard readStr(s, 5) # Ignore 5 bytes for future use
  case frame.cel.celType:
    of 0:
      pxd.debug.warn("ASEPRITE: Unsupported cel type: Raw Image Data")
    of 1:
      pxd.debug.warn("ASEPRITE: Unsupported cel type: Linked Cel")
    of 2:
      readCompressedImage(aseprite, frame, chunk, s)
    else:
      pxd.debug.warn(&"ASEPRITE: Unsupported cel type: {frame.cel.celType}")
  state.chunkType = chunk.chunkType
  state.chunk     = cast[pointer](frame.cel.addr)


proc readAsepriteFrameTag(aseprite: Aseprite, frame: var AsepriteFrame, chunk: var AsepriteChunk) =
  # Not very intuitive, as far as I understood all tags are located in first frame chunks
  if chunk.chunkType != 0x2018: return
  var s = newStringStream(chunk.chunkData.toString())
  var tagsCount = readU16LE(s).int
  discard readStr(s, 8) # Ignore 8 bytes for future use
  aseprite.tags = newSeq[AsepriteTag](tagsCount)
  for tag in aseprite.tags.mitems:
    tag.frameFrom = readU16LE(s).int
    tag.frameTo = readU16LE(s).int
    tag.animDirection = readChar(s).int
    tag.repeatTimes = readU16LE(s).int
    discard readStr(s, 6) # Ignore 5 bytes for future use
    discard readStr(s, 3) # Deprecated, RGB values of the tag color
    discard readChar(s)   # Extra byte (zero)
    tag.name = readStr(s, readU16LE(s).int)


proc readAsepriteChunks(aseprite: Aseprite, frame: var AsepriteFrame, s: Stream) =
  let chunksCount = frame.header.chunks
  frame.chunks = newSeq[AsepriteChunk](chunksCount)
  for chunk in frame.chunks.mitems:
    readAsepriteFrameChunk(chunk, s)
    readAsepriteLayer(aseprite, frame, chunk)
    readAsepriteUserData(aseprite, frame, chunk)
    readAsepriteFrameCel(aseprite, frame, chunk)
    readAsepriteFrameTag(aseprite, frame, chunk)


proc readAsepriteChunks(aseprite: Aseprite, s: Stream) =
  let framesCount = aseprite.header.frames
  var frames = newSeq[AsepriteFrame](framesCount)
  for frame in frames.mitems:
    readAsepriteChunkHeader(frame, s)
    readAsepriteChunks(aseprite, frame, s)
  aseprite.frames = frames


proc load*(api: AssetAPI, relativePath: string, typeof: typedesc[Aseprite]): Aseprite =
  let path = pxd.filesystem.path(relativePath)
  let s = newFileStream(path, fmRead)
  if s.isNil:
    pxd.debug.error(&"ASSETS: Failed to open file: {path}")
    return HANDLE_NULL.Aseprite
  result = make(Aseprite)
  readAsepriteHeader(result, s)
  readAsepriteChunks(result, s)


proc unload*(api: AssetAPI, aseprite: Aseprite) =
  aseprite.drop()


proc getSmallestPowerOf2(aseprite: Aseprite, border: int): int =
  let w = aseprite.header.width.int
  let h = aseprite.header.height.int
  let framesCount = aseprite.header.frames
  let totalArea = ((w + 2 * border)*(h + 2 * border)) * framesCount
  result = pxd.math.smallestPowerOf2(int(sqrt(float(totalArea))))


proc addTransparentBorder(celData: var seq[uint8], width: int, height: int, border: int, channelsCount: int): TempImage =
  var image: TempImage
  if border == 0:
    image.width = width
    image.height = height
    image.data = celData
    return image
  let
    newWidth = width + 2 * border
    newHeight = height + 2 * border
  image.data = newSeq[byte](channelsCount * newWidth * newHeight)
  image.width = newWidth
  image.height = newHeight
  for y in 0..<height:
    for x in 0..<width:
      let oldPos = channelsCount * (y * width + x)
      let newPos = channelsCount * ((y + border) * newWidth + (x + border))
      for c in 0 ..< channelsCount:
        image.data[newPos + c] = celData[oldPos + c]
  image


proc generateAsepriteAtlas(aseprite: Aseprite, atlas: SpriteAtlas, atlasParams: SpriteAtlasParams) =
  # Trim mode atlas generator from aseprite binary
  let framesCount = aseprite.header.frames
  let channelsCount = aseprite.header.colorDepth div 8
  let atlasTextureSize = getSmallestPowerOf2(aseprite, atlasParams.border)
  var atlasPixels      = newSeq[byte](atlasTextureSize * atlasTextureSize * channelsCount)
  var startX = 0 + atlasParams.border
  var startY = 0 + atlasParams.border
  var currentRowHeight = 0
  var spritesParam = newSeq[SpriteParams](framesCount)
  let frameWidth  = aseprite.header.width.float
  let frameHeight = aseprite.header.height.float
  var originX = frameWidth  / 2.0
  var originY = frameHeight / 2.0
  var maxHeight = -float.high
  var maxWidth  = -float.high
  if state.pivotX != float.high and state.pivotY != float.high:
    originX = state.pivotX
    originY = state.pivotY
  for frameIndex in 0 ..< framesCount:
    let frame = aseprite.frames[frameIndex].addr
    let spriteHeight = frame.cel.height.float
    let spriteWidth  = frame.cel.width.float
    if maxHeight < spriteHeight:
      maxHeight = spriteHeight
    if maxWidth < spriteWidth:
      maxWidth = spriteWidth
  for frameIndex in 0 ..< framesCount:
    var offsetX = 0.0
    var offsetY = 0.0
    let frame = aseprite.frames[frameIndex].addr
    let spriteHeight = frame.cel.height
    let spriteWidth  = frame.cel.width
    offsetY = (maxHeight - spriteHeight.float) / runtime_ppu[]
    offsetX = (maxWidth  - spriteWidth.float) / runtime_ppu[]
    for y in 0 ..< spriteHeight:
      for x in 0 ..< spriteWidth:
        let oldPos = (y * spriteWidth + x) * channelsCount
        let newPos = ((startY + y) * atlasTextureSize + startX + x) * channelsCount
        for c in 0 ..< channelsCount:
          atlasPixels[newPos + c] = frame.cel.celData[oldPos + c]
      if frame.cel.pivotX != float.high and frame.cel.pivotY != float.high:
        originX = frame.cel.pivotX
        originY = frame.cel.pivotY
    let originX = 1 - originX / frameWidth.float
    let originY = 1 - originY / frameHeight.float
    spritesParam[frameIndex] = SpriteParams(
    name: "",
    sprx: startX.float,
    spry: startY.float,
    sprw: spriteWidth.float,
    sprh: spriteHeight.float,
    px: originX,
    py: originY,
    offsetY: offsetY,
    offsetX: offsetX
    )
    startX += spriteWidth  + atlasParams.border
    if startX + spriteWidth > atlasTextureSize:
      startX = 0 + atlasParams.border
      startY += currentRowHeight + atlasParams.border
      currentRowHeight = 0
    currentRowHeight = max(currentRowHeight, spriteHeight)
  atlas.sprites = newSeq[Sprite](spritesParam.len)
  var texParam = Texture2DParams()
  texParam.width = atlasTextureSize
  texParam.height = atlasTextureSize
  texParam.pixelPerfect = true
  texParam.pixels = atlasPixels
  texParam.channels = channelsCount
  var texture = pxd.assets.load(texParam, Texture2D)
  for i, spriteParam in iterators.mpairs(spritesParam):
    atlas.sprites[i] = pxd.engine.loadAseprite(texture, spriteParam)
  #saveBMP32("image32.bmp", atlasPixels, atlasTextureSize, atlasTextureSize)


proc toSpriteAtlas*(aseprite: Aseprite, atlasParams: SpriteAtlasParams): SpriteAtlas =
  var atlas = make(SpriteAtlas)
  generateAsepriteAtlas(aseprite, atlas, atlasParams)
  atlas


proc toSpriteAnimations*(aseprite: Aseprite, sequences: var SpriteSequences, atlasParams: SpriteAtlasParams) =
  var atlas = toSpriteAtlas(aseprite, atlasParams)
  if aseprite.tags.len == 0:
    var sequence: SpriteSequence
    for index in 0..aseprite.frames.high:
      var times = std_math.round(float aseprite.frames[index].header.frameDuration / atlasParams.msPerFrame).int
      times = clamp(times, 1, 100)
      repeat(times):
        sequence.items.add(atlas.sprites[index])
    sequences[GetKey("idle").value] = sequence
  else:
    for tag in aseprite.tags.mitems:
      var sequence: SpriteSequence
      for index in tag.frameFrom..tag.frameTo:
        var times = std_math.round(float aseprite.frames[index].header.frameDuration / atlasParams.msPerFrame).int
        times = clamp(times, 1, 100)
        repeat(times):
          sequence.items.add(atlas.sprites[index])
      sequences[GetKey(tag.name).value] = sequence


proc load*(pack: AssetPack, relativePath: string, _: typedesc[Aseprite]): Aseprite =
  let tag = relativePath & $Aseprite
  result = pxd.assets.load(relativePath, Aseprite)
  pack.items[tag] = (Handle)result


proc get*(pack: AssetPack, relativePath: string, typeof: typedesc[Aseprite]): Aseprite {.discardable.} =
  let tag = relativePath & $typeof
  if not pack.has(relativePath, Aseprite):
    pxd.debug.error("ASSETS: Asset is not found in the pack!")
  (Aseprite)pack.items[tag]
