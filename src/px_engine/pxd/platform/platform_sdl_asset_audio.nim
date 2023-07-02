import px_engine/vendor/sdl_mixer as mix
import px_engine/pxd/definition/api
import px_engine/pxd/data/data_mem_pool
import platform_sdl_audio_d
export platform_sdl_audio_d


type Music = platform_sdl_audio_d.Music


GEN_MEM_POOL(SoundObj, Sound)
GEN_MEM_POOL(MusicObj, Music)

#------------------------------------------------------------------------------------------
# @api audio loader
#------------------------------------------------------------------------------------------
proc load*(api: EngineAPI, path: string, typeof: typedesc[Sound]): Sound =
  var asset = make(SoundObj)
  asset.get.data = mix.loadWAV(path)
  result = asset


proc load*(api: EngineAPI, path: string, typeof: typedesc[Music]): Music =
  var asset = make(MusicObj)
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