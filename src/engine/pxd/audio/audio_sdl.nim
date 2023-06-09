import std/strformat
import vendor/sdl_mixer as mix
import engine/pxd/api
import engine/pxd/m_debug


proc initAudio*(api: EngineAPI) =
  const sampleFrequency = 22050
  const channels        = 2 # 1-mono, 2-stereo
  const chunkSize       = 1024
  var result = mix.openAudio(sampleFrequency, mix.DEFAULT_FORMAT, channels, chunkSize)
  if result != 0:
    debug.fatal("AUDIO", &"Failed to open audio: {mix.getError()}")


proc shutdownAudio*(api: EngineAPI) =
  mix.quit()