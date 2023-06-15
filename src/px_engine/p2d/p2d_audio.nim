import px_engine/Px
import px_engine/p2d/api
import px_engine/pxd/api
import px_engine/assets/asset_audio


proc play*(api: P2DAudioAPI, source: Px.Music) =
  engine.playMusic(source)


proc play*(api: P2DAudioAPI, source: Px.Sound) =
  engine.playSound(source)


proc pauseAll*(api: P2DAudioAPI) =
  engine.pauseMusic()
  engine.pauseAllSounds()


proc pauseAllSounds*(api: P2DAudioAPI) =
  engine.pauseAllSounds()


proc pauseMusic*(api: P2DAudioAPI) =
  engine.pauseMusic()