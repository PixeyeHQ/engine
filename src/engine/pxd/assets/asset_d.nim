import std/hashes
import pxd/api

type Asset* = distinct Handle


type AssetObj* = object
  path*:     string
  scope*:    string
  pathHash*: Hash
  assetId*:  Handle = HANDLE_NULL