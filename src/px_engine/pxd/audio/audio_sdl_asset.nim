import px_engine/vendor/sdl_mixer as mix
import px_engine/pxd/api
import px_engine/pxd/data/m_mem_pool
import px_engine/pxd/m_debug
import px_engine/px as Px

GEN_MEM_POOL(Px.SoundObj, Px.Sound)
GEN_MEM_POOL(Px.MusicObj, Px.Music)

#------------------------------------------------------------------------------------------
# @api audio loader
#------------------------------------------------------------------------------------------
proc load*(api: EngineAPI, path: string, typeof: typedesc[Px.Sound]): Px.Sound =
  var asset = make(Px.SoundObj)
  asset.get.data = mix.loadWAV(path)
  result = asset


proc load*(api: EngineAPI, path: string, typeof: typedesc[Px.Music]): Px.Music =
  var asset = make(Px.MusicObj)
  asset.get.data = mix.loadMUS(path)
  result = asset


proc playSound*(api: EngineAPI, source: Px.Sound) =
  discard mix.playChannel(-1, cast[Chunk](source.get.data), 0)


proc playMusic*(api: EngineAPI, source: Px.Music) =
  discard mix.playMusic(source.get.data, -1)


proc pauseMusic*(api: EngineAPI) =
  mix.pauseMusic()


proc pauseAllSounds*(api: EngineAPI) =
  mix.pause(-1)
