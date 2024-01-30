import std/streams
import std/strformat
import zlib


proc toString*(bytes: openarray[byte]): string =
  result = newString(bytes.len)
  copyMem(result[0].addr, bytes[0].unsafeAddr, bytes.len)


proc decompressZlibBytes*(input: seq[uint8]): seq[uint8] =
  var buffer {.global.} : array[2048*2048,uint8] # 2k texture size
  var stream: ZStream
  var output: seq[uint8]
  stream.zalloc = nil
  stream.zfree  = nil
  stream.opaque = nil
  stream.next_in  = input[0].addr
  stream.avail_in = input.len.cuint

  var state = stream.inflateInit()
  if state!=Z_OK: echo &"ZLIB Error: {state}"

  while true:
    stream.next_out = buffer[0].addr
    stream.avail_out = buffer.len.cuint

    state = inflate(stream, Z_NO_FLUSH)

    if state == Z_STREAM_END:
      output.add(buffer[0..^stream.avail_out.int])
      break

    if state != Z_OK:
      echo &"ZLIB Error: {state}"
      discard
    output.add(buffer[0..^stream.avail_out.int])

  discard stream.inflateEnd()
  return output


proc readU16LE*(s: Stream): uint16 =
  result = uint16(s.readChar) or (uint16(s.readChar) shl 8)


proc readU32LE*(s: Stream): uint32 =
  result = uint32(readU16LE(s)) or (uint32(readU16LE(s)) shl 16)


proc read16LE*(s: Stream): int16 =
  result = int16(s.readChar) or (int16(s.readChar) shl 8)


proc read32LE*(s: Stream): int32 =
  result = int32(read16LE(s)) or (int32(read16LE(s)) shl 16)
