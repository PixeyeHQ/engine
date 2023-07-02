#[
  Not production ready, just a simple wrapper from sdl mixer to mark audio presense.
  This module will be expanded in future on demand of upcoming game projects.
]#
import std/strformat
import px_engine/vendor/sdl_mixer as mix
import px_engine/pxd/definition/api
import px_engine/pxd/m_debug
let debug = pxd.debug

proc initAudio*(api: EngineAPI) =
  const sampleFrequency = 22050
  const channels        = 2 # 1-mono, 2-stereo
  const chunkSize       = 1024
  var result = mix.openAudio(sampleFrequency, mix.DEFAULT_FORMAT, channels, chunkSize)
  if result != 0:
    pxd.debug.fatal("AUDIO", &"Failed to open audio: {mix.getError()}")


proc shutdownAudio*(api: EngineAPI) =
  mix.quit()