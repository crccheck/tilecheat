# Helpers.coffee
#
# Random utilities not directly related to the library

# Alias for getElementById
$ = (s) -> document.getElementById(s)


# ECMAScript Harmony Proposal polyfill simplified to not take position argument.
if !String::startsWith
  String::startsWith = (s) -> this.substring(0, s.length) == s
if !String::endsWith
  String::endsWith = (s) -> this.substring(this.length - s.length) == s
copy = (o) ->
  r = {}
  for k, v of o
    r[k] = v
  return r


# http://coffeescript.org/documentation/docs/helpers.html
extend = (object, properties) ->
  for key, val of properties
    object[key] = val
  object
