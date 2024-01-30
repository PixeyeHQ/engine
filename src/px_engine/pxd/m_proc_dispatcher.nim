# concept of dynamic proc dispatcher. Pretty easy to add. Can be used in procs with params too.
# much faster than methods (X7 times), with macro can be not that cumbersome to use.
#[
  proc runDispatcher*(self: baseObject) =
    case self.kind.value: # IndexKey
      of 0:
        run(ObjA(self))
      of 1:
        run(ObjB(self))
      else:
        discard
  proc runDispatcher*(self: baseObject, arg: int) =
    case self.kind.value: # IndexKey
      of 0:
        run(ObjA(self), arg)
      of 1:
        run(ObjB(self), arg)
      else:
        discard
]#


# template run*(self: baseObject) = 
#   when compiles(runDispatcher(self)):
#     runDispatcher(self)
  

# macro genDispatcher*[T:enum](apiName: untyped, args: untyped, kindof: typedesc[T]): untyped =
#   var apis = ($apiName).split(',')
#   var margs = ($args).split(',')
#   var kinds = newSeq[string]()
#   for tpl in getType(kindof):
#     if tpl.kind == nnkEnumTy:
#       for v in tpl.items:
#         if v.kind == nnkSym:
#           kinds.add(v.strVal)
#   proc genCase(api: string, vars: seq[NimNode]): NimNode =
#     var caseStmt = nnkCaseStmt.newTree(
#           nnkDotExpr.newTree(
#             newIdentNode("self"),
#             newIdentNode("kind")
#       )
#     )
#   #vars
#     for k in kinds:
#       let enumVal = newIdentNode(k)
#       let typeVal = substr(k, 2, k.high)
#       var call =  nnkCall.newTree(
#                   newIdentNode(api),
#                   nnkCall.newTree(
#                     newIdentNode(typeVal),
#                     newIdentNode("self"),
#                     ))
#       call.add(vars)
#       caseStmt.add(
#         nnkOfBranch.newTree(
#               enumVal,
#               nnkStmtList.newTree(
#                 call)))
#     result = nnkStmtList.newTree(caseStmt)
  


#   result = nnkStmtList.newTree()
#   for a in apis:
#     var vars   = newSeq[NimNode]()
#     var params = nnkFormalParams.newTree(
#       newEmptyNode(),
#       nnkIdentDefs.newTree(
#         newIdentNode("self"),
#         newIdentNode(margs[0]),
#         newEmptyNode()
#       )
#     )
#     if margs.len > 1:
#       for i in 1..<margs.len:
#          var elem = margs[i].split(':')
#          vars.add(newIdentNode(elem[0]))
#          params.add(
#           nnkIdentDefs.newTree(
#             newIdentNode(elem[0]),
#             newIdentNode(elem[1]),
#             newEmptyNode()
#           )
#           )

#     let api = a
#     var procDef = nnkProcDef.newTree(
#       nnkPostfix.newTree(
#         newIdentNode("*"),
#         newIdentNode(api),
#       ),
#       newEmptyNode(),
#       newEmptyNode(),
#       params,
#       newEmptyNode(),
#       newEmptyNode(),
#       genCase(api,vars)
#     )
#     result.add(procDef)