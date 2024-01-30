import ../px_engine_pxd
import ../px_engine_assets
import api


proc play*(api: P2DAudioAPI, source: Music) =
  pxd.engine.playMusic(source)


proc play*(api: P2DAudioAPI, source: Sound) =
  pxd.engine.playSound(source)


proc pauseAll*(api: P2DAudioAPI) =
  pxd.engine.pauseMusic()
  pxd.engine.pauseAllSounds()


proc pauseAllSounds*(api: P2DAudioAPI) =
  pxd.engine.pauseAllSounds()


proc pauseMusic*(api: P2DAudioAPI) =
  pxd.engine.pauseMusic()