import std/hashes
import px_engine/pxd/definition/api

type Asset* = distinct Handle


type AssetObj* = object
  path*:     string
  scope*:    string
  pathHash*: Hash
  assetId*:  Handle = HANDLE_NULL