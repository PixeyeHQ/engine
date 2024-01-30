import ../m_pass
when defined(opengl):
  pass renderer/renderer_gl
  import renderer/renderer_gl_commands as rxd; export rxd
  import renderer/renderer_gl_commands_p2d as r2d; export r2d
pass renderer/renderer_d