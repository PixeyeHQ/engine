template onCompile*(expression: untyped) =
  when compiles(expression):
    expression


template onCompile*(expression: untyped, code: untyped) =
  when compiles(expression):
    expression
    code