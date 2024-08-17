import std/[strutils, sequtils, uri]

import karax/[kbase, karax, karaxdsl, vdom, jstrutils]

import ../[packages, style, context]
# import ../components/package
import ../utils

type
  Query* = object
    all, name, tag, license = "".kstring

proc parseQuery*(s: kstring): Query =
  result = Query()
  if ":" notin s:
    result.all = s; return

  let parts = s.split(" ")
  for part in parts:
    if ":" in part:
      let
        subparts = part.split(":")
        k = subparts[0]
        v = subparts[1]
      case k:
        of "name":
          result.name = v
        of "tag":
          result.tag = v.replace("-")
        of "license":
          result.license = v
        else: discard
    else:
      result.all &= part

proc toLowerAscii(ks: kstring): kstring {.inline.} =
  ($ks).toLowerAscii().kstring

proc genericSearchString(p: NimPackage): kstring =
  (@[p.url, p.name, p.description, p.tags.join(" ").kstring].join(" ").kstring).toLowerAscii()

proc searchPackages*(q: Query): seq[NimPackage] =
  if q == Query():
    result = ctx.nimpkgs.packages.values.toSeq()
    return

  for name, pkg in ctx.nimpkgs.packages:
    let searchStr = pkg.genericSearchString()
    if (q.name notin pkg.name) or (q.license notin pkg.license) or
        (q.tag != "".kstring and (q.tag notin pkg.tags)):
      continue

    if q.all in searchStr:
      result.add pkg

proc getSearchFromUri*(): kstring =
  var url = currentUri()
  if url.query == "": return ""
  for k, v in decodeQuery(url.query):
    if k == "query":
      return v.kstring

proc getSearchInput*() =
  let searchInput = getVNodeById("search").getInputText
  setSearchUrl(searchInput)()

proc searchBar*(value = jss""): Vnode =
  buildHtml(tdiv(class = "flex flex-row my-2 grow")):
    input(`type` = "text", class = "bg-ctp-crust md:mx-3 mx-1 p-2 grow".kstring & borderStyle, `id` = "search",
          placeholder = "query", value = value,
          onChange = getSearchInput)
    button(`type` = "button", class = borderStyle & "p-2 flex items-center",
        onClick = getSearchInput):
      tdiv(class = "i-mdi-magnify")
      text "search"

