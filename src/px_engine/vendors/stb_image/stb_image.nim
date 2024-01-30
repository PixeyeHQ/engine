{.used.}
{.pragma: stbcall, cdecl.}
{.compile: "stb_image.c".}

type STBIException* = object of ValueError

const
    STB_IMAGE_DEFAULT*    = 0 # Used by req_comp
    STB_IMAGE_GREY*       = 1 # Monochrome
    STB_IMAGE_Y*          = 1 # (for stb_image_write)
    STB_IMAGE_GREY_ALPHA* = 2 # Monochrome w/ Alpha
    STB_IMAGE_YA*         = 2 # (for stb_image_write)
    STB_IMAGE_RGB*        = 3 # Red, Green, Blue
    STB_IMAGE_RGBA*       = 4 # Red, Green, Blue, Alpha

# depends on your C compiler configuration, most of the times you need to specify the calling convention explicitly, 
# for example: stdcall for msvc or cdecl for gcc

proc stbi_load*(filename: cstring, x,y, comp: var cint, req_comp: cint):
  ptr char {.importc: "stbi_load",cdecl.}

proc stbi_image_free*(data: ptr cchar) 
  {.importc: "stbi_image_free",cdecl.}

proc stbi_failure_reason_impl(): cstring
  {.importc: "stbi_failure_reason",cdecl.}

proc stbi_failure_reason*(): string = $stbi_failure_reason_impl()


proc stbi_set_flip_vertically_on_load*(flag_true_if_should_flip: cint)
  {.importc: "stbi_set_flip_vertically_on_load",cdecl.}

proc stbi_set_flip_vertically_on_load_thread*(flag_true_if_should_flip: cint)
  {.importc: "stbi_set_flip_vertically_on_load_thread",cdecl.}