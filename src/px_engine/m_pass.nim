import std/macros


macro pass_gen(module: untyped): untyped =
  var statement = nnkStmtList.newTree()
  if module.len > 0:
    statement.add(nnkImportStmt.newTree(
      module
    ))
    if module[module.len-1].kind == nnkBracket:
      for i in 0..<module[module.len-1].len:
        statement.add(nnkExportStmt.newTree(module[module.len-1][i]))
    else:
      statement.add(nnkExportStmt.newTree(module[module.len-1]))
  else:
    statement.add(nnkImportStmt.newTree(
      module
    ))
    statement.add(nnkExportStmt.newTree(
      module
    ))
  return statement


template pass_members*(module: untyped, members: varargs[untyped]) =
  when varargsLen(members) > 0:
      import module
      export members


template pass*(module: untyped, moduleName: untyped) =
  import module as moduleName
  export moduleName


template pass*(module: untyped) =
  pass_gen(module)


template pass_except*(module: untyped, moduleName: untyped, members: varargs[untyped]) =
  import module as moduleName
  export moduleName except
    members


# [?] group together plugin_gen and plugin_gen_varargs?
macro plugin_gen(module: untyped): untyped =
  var statement = nnkStmtList.newTree(nnkImportStmt.newTree())
  if module.len == 0:
    let moduleNode = module
    statement[0].add(
      nnkInfix.newTree(
        newIdentNode("as"),
        nnkInfix.newTree(
          newIdentNode("/"),
          module,
          newIdentNode("api")
        ),
        moduleNode
      )
    )
  elif module[module.len-1].kind == nnkBracket:
    var path = nnkInfix.newTree(
      module[0..<module.len-1]
    )
    var bracketStmt = nnkBracket.newNimNode()
    var tokens = newSeq[NimNode]()
    for i in 0..<module[module.len-1].len:
      let moduleNode = module[module.len-1][i]
      bracketStmt.add(
        nnkInfix.newTree(
          newIdentNode("as"),
          nnkInfix.newTree(
            newIdentNode("/"),
            moduleNode,
            newIdentNode("api")
          ),
          moduleNode
        )
      )
    path.add(bracketStmt)
    statement[0].add(path)
  else:
    let moduleNode = module[module.len-1]
    statement[0].add(
      nnkInfix.newTree(
        newIdentNode("as"),
        nnkInfix.newTree(
          newIdentNode("/"),
          module,
          newIdentNode("api")
        ),
        moduleNode
      )
    )
  return statement


macro plugin_gen_varargs(module: varargs[untyped]): untyped =
  var statement = nnkStmtList.newTree(nnkImportStmt.newTree())
  for m in module:
    statement[0].add(
        nnkInfix.newTree(
          newIdentNode("as"),
          nnkInfix.newTree(
            newIdentNode("/"),
            m,
            newIdentNode("api")
          ),
          m
        )
      )
  return statement


template plugin*(module: untyped): untyped =
  plugin_gen(module)


template plugin*(module: varargs[untyped]): untyped =
  plugin_gen_varargs(module)