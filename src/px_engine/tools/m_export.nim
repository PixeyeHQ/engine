template EXPORT_MEMBERS*(module: untyped, members: varargs[untyped]) =
  when varargsLen(members) > 0:
      import module
      export members


template EXPORT*(module: untyped, moduleName: untyped) =
  import module as moduleName
  export moduleName


template EXPORT_EXCEPT*(module: untyped, moduleName: untyped, members: varargs[untyped]) =
  import module as moduleName
  export moduleName except
    members