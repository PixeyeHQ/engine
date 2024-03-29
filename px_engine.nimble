# Package
version       = "2024.0.3"
author        = "Dmitry Igorevich Mitrofanov (@pixeye)"
description   = "2d/3d Game engine"
license       = "Zlib"
srcDir        = "src"


# Dependencies
requires "nim      >= 1.0"
requires "sdl2_nim >= 2.0.14.3"
requires "https://github.com/PixeyeHQ/px.nim.pods >= 2023.12.1"


var ex = "ex"
var debug = "debug"

proc run(name, releaseMode="danger") =
  exec "nim cpp --mm:orc -d:stacktrace:off -d:useMalloc -d:" & releaseMode & " -o=bin/examples/ -r examples/" & name & ".nim"


task ex_camera, ex:
  run "ex_camera"
task ex_camera_d, ex:
  run "ex_camera", debug

task ex_interaction, ex:
  run "ex_interaction"
task ex_interaction_d, ex:
  run "ex_interaction", debug

task ex_pods, ex:
  run "ex_pods"
task ex_pods_d, ex:
  run "ex_pods", debug

task ex_ecs, ex:
  run "ex_ecs"
task ex_ecs_d, ex:
  run "ex_ecs", debug

task ex_input, ex:
  run "ex_input"
task ex_input_d, ex:
  run "ex_input", debug

task ex_minimal, ex:
  run "ex_minimal"
task ex_minimal_d, ex:
  run "ex_minimal", debug

task ex_renderer, ex:
  run "ex_renderer"
task ex_renderer_d, ex:
  run "ex_renderer", debug

task ex_text, ex:
  run "ex_text"
task ex_text_d, ex:
  run "ex_text", debug

task ex_test, ex:
  run "ex_test"
task ex_test_d, ex:
  run "ex_test", debug

task ex_physics2d, ex:
  run "ex_physics2d"
task ex_physics2d_d, ex:
  run "ex_physics2d", debug