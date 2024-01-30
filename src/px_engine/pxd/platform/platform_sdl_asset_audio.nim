#[
  Not production ready, just a simple wrapper from sdl mixer to mark audio presense.
  This module will be expanded in future on demand of upcoming game projects.
]#
import std/strformat
import ../api
import ../m_memory
import ../m_debug
import ../../vendors/sdl_mixer as mix

type Sound_Obj* = object
  data*:    pointer
  channel*: cint
type Sound* = distinct Handle

type Music_Obj* = object
  data*: pointer
type Music* = distinct Handle


proc initAudio*(api: EngineAPI) =
  const sampleFrequency = 22050
  const channels        = 2 # 1-mono, 2-stereo
  const chunkSize       = 1024
  var result = mix.openAudio(sampleFrequency, mix.DEFAULT_FORMAT, channels, chunkSize)
  if result != 0:
    pxd.debug.fatal("AUDIO: Failed to open audio: {mix.getError()}")


proc shutdownAudio*(api: EngineAPI) =
  mix.quit()


pxd.memory.genPoolTyped(Sound, SoundObj)
pxd.memory.genPoolTyped(Music, MusicObj)

#------------------------------------------------------------------------------------------
# @api audio loader
#------------------------------------------------------------------------------------------
proc load*(api: AssetAPI, path: string, typeof: typedesc[Sound]): Sound =
  var asset = make(Sound)
  asset.get.data = mix.loadWAV(path)
  result = asset


proc load*(api: AssetAPI, path: string, typeof: typedesc[Music]): Music =
  var asset = make(Music)
  asset.get.data = mix.loadMUS(path)
  result = asset


proc playSound*(api: EngineAPI, source: Sound) =
  discard mix.playChannel(-1, cast[Chunk](source.get.data), 0)


proc playMusic*(api: EngineAPI, source: Music) =
  discard mix.playMusic(source.get.data, -1)


proc pauseMusic*(api: EngineAPI) =
  mix.pauseMusic()


proc pauseAllSounds*(api: EngineAPI) =
  mix.pause(-1)