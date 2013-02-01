# CONFIGURATION
n_slices = 4
vignette_fix = 0  # black levels below this will have noise artificially added
retries = 0

# scope hack
slice_w = 0
width = 0


$ = (s) -> document.getElementById(s)


getPixel = (d, x, y) ->
  index = (x + y * width) * 4
  rgb =
    r: d[index]
    g: d[index + 1]
    b: d[index + 2]
  lab = Color.convert(rgb, "lab")
  if lab.l < vignette_fix
    lab.l = Math.floor(Math.random() * 100)
  return lab


# for debugging, replace getPixel with this to see which pixels are getting touched.
setPixel = (d, x, y) ->
  index = (x + y * width) * 4
  rgba = [d[index], d[index + 1], d[index + 2], d[index + 3]]
  # console.log rgba
  d[index] = 0
  d[index + 1] = 0
  d[index + 2] = 0
  return d


# arguments:
#  d: imageData
#  m: horizontal slice coordinate (0 based)
#  n: vertical slice coordinate (0 based)
getEdgeData = (d, m, n) ->
  x_begin = m * slice_w
  x_end = x_begin + slice_w - 1
  y_begin = n * slice_w
  y_end = y_begin + slice_w - 1
  data =
    id: "#{m}.#{n}"
    grid:
      m: m
      n: n
    n: []
    s: []
    e: []
    w: []
  for i in [x_begin..x_end]
    data.n.push(getPixel d, i, y_begin)
    data.s.push(getPixel d, i, y_end)
  for j in [y_begin..y_end]
    data.e.push(getPixel d, x_begin, j)
    data.w.push(getPixel d, x_end, j)
  return data


# get the distance between two edges
distance = (d1, d2) ->
  sum = 0
  for color1, idx in d1
    color2 = d2[idx]
    sum += Math.pow(color2.l - color1.l, 2)
    sum += Math.pow(color2.a - color1.a, 2)
    sum += Math.pow(color2.b - color1.b, 2)
  return Math.sqrt sum


# for Array.sort
bestMatchSort = (a, b) -> a[0] - b[0]


# find the best neighbor for `targetSlice` from `edgeData`
findNeighbor = (targetSlice, edgeData, edges="news")->
  allMatches = []
  if "n" in edges
    # find north match
    currentMatches = []
    for data in edgeData
      currentMatches.push([distance(targetSlice.n, data.s), data.id, "n"])
    allMatches.push(currentMatches.sort(bestMatchSort)[0])
  if "s" in edges
    # find south match
    currentMatches = []
    for data in edgeData
      currentMatches.push([distance(targetSlice.s, data.n), data.id, "s"])
    allMatches.push(currentMatches.sort(bestMatchSort)[0])
  if "e" in edges
    # find east match
    currentMatches = []
    for data in edgeData
      currentMatches.push([distance(targetSlice.e, data.w), data.id, "e"])
    allMatches.push(currentMatches.sort(bestMatchSort)[0])
  if "w" in edges
    # find west match
    currentMatches = []
    for data in edgeData
      currentMatches.push([distance(targetSlice.w, data.e), data.id, "w"])
    allMatches.push(currentMatches.sort(bestMatchSort)[0])

  bestMatch = allMatches.sort(bestMatchSort)[0]


# return empty sides
#
# if a tile already has blocks above and below, return "ew" so findneighber
# knows not to look north or south.
window.validEdge = validEdges = (startCoord, resultGrid) ->
  bits = startCoord.split('.')
  x = +bits[0]
  y = +bits[1]
  edges = ""
  if !resultGrid["#{x}.#{y-1}"]
    edges += "n"
  if !resultGrid["#{x}.#{y+1}"]
    edges += "s"
  if !resultGrid["#{x-1}.#{y}"]
    edges += "e"
  if !resultGrid["#{x+1}.#{y}"]
    edges += "w"
  return edges


# make sure the top left is at 0.0
normalizeResultGrid = (input) ->
  minX = 99
  minY = 99
  for own key of input
    bits = key.split('.')
    minX = Math.min(minX, bits[0])
    minY = Math.min(minY, bits[1])
  newObj = {}
  for own key, value of input
    bits = key.split('.')
    newObj["#{bits[0] - minX}.#{bits[1] - minY}"] = value
  return newObj


# get the shape of a grid
shape = (input) ->
  minX = 99
  minY = 99
  maxX = -99
  maxY = -99
  for own key of input
    bits = key.split('.')
    minX = Math.min(minX, bits[0])
    maxX = Math.max(maxX, bits[0])
    minY = Math.min(minY, bits[1])
    maxY = Math.max(maxY, bits[1])
  return [maxX - minX + 1, maxY - minY + 1]


# get edge data from the raw image data
getAllEdgeData = (imageDataArray) ->
  edgeData = []
  slices = new Array(n_slices * n_slices)
  for num, i in slices
    row = Math.floor(i / n_slices)
    col = i % n_slices
    edgeData.push getEdgeData(imageDataArray, row, col)
  return edgeData



# get a resultGrid based on the edgeData
  # attempt 1, the long, stupid, dirty way
getResult = (edgeData)->
  # pick a starting tile
  start = edgeData[Math.floor(Math.random() * edgeData.length)]
  edgeData = (x for x in edgeData when x != start)

  # hold the result
  resultGrid = {}
  reverseResultGrid = {}
  positionX = 0
  positionY = 0
  resultGrid["#{positionX}.#{positionY}"] = start.id
  reverseResultGrid[start.id] = "#{positionX}.#{positionY}"
  placedTiles = [start]

  window.resultGrid = resultGrid  # debug
  window.reverseResultGrid = reverseResultGrid  # debug
  window.placedTiles = placedTiles  # debug

  threshold = 500  # match threshold, distance between edges should be under this
  giveUpThreshold = 50  # give up after this many iterations

  while edgeData.length and (giveUpThreshold-- > 0)
    # console.log "Iteration Start", placedTiles.length, giveUpThreshold
    attempts = 15
    neighbor = null
    # console.log "Looking for neighbor for scrambled #{start.id} in directions #{validEdges(reverseResultGrid[start.id], resultGrid)}"
    neighbor = findNeighbor(start, edgeData, validEdges(reverseResultGrid[start.id], resultGrid))
    # while (neighbor = findNeighbor(start, edgeData, validEdges(reverseResultGrid[start.id], resultGrid)))[0] > threshold
    #   # no neighbor meeting threshold found, pick a new start
    #   console.log "no neighbor meeting threshold found, pick a new start", neighbor
    #   start = placedTiles[Math.floor(Math.random() * placedTiles.length)]
    #   bits = reverseResultGrid[start.id].split('.')
    #   positionX = bits[0]
    #   positionY = bits[1]
    #   if !--attempts
    #     attempts = 15
    #     threshold = threshold * 1.1
    #     console.log "Raising threshold: #{threshold}"
    #   if threshold > 100000
    #     console.error "oops, threshold reached"
    #     return
    # console.log "Neighbor found", neighbor
    newEdgeData = []
    for x in edgeData
      if x.id == neighbor[1]
        start = x
        placedTiles.push x
      else
        newEdgeData.push x
    switch neighbor[2]
      when "n" then positionY--
      when "s" then positionY++
      when "e" then positionX--
      when "w" then positionX++
    solvedCoord = "#{positionX}.#{positionY}"
    if !resultGrid[solvedCoord]
      edgeData = newEdgeData
      resultGrid[solvedCoord] = neighbor[1]
      reverseResultGrid[neighbor[1]] = solvedCoord
    else
      console.error "oops, solved #{solvedCoord} is already taken by #{resultGrid[solvedCoord]}"
      giveUpThreshold = -1  # give up

  # console.log "finished with #{edgeData.length} left and #{giveUpThreshold}"

  return resultGrid

# helpers
if !String::startsWith
  String::startsWith = (s) -> this.substring(0, s.length) == s
if !String::endsWith
  String::endsWith = (s) -> this.substring(this.length - s.length) == s
copy = (o) ->
  r = {}
  for k, v of o
    r[k] = v
  return r


# attempt 2
getResult2 = (tiles)->
  # build map of every edge distance possible.
  #
  # I think this is O(4n!) keys are <tile><orientation><tile>, where orientation
  # is (v)ertical or (h)orizontal
  buildMap = ->
    map = {}
    for tile1, i in tiles
      for tile2 in tiles[(i + 1)..]
        map["#{tile1.id}h#{tile2.id}"] = distance(tile1.w, tile2.e)
        map["#{tile2.id}h#{tile1.id}"] = distance(tile2.w, tile1.e)
        map["#{tile1.id}v#{tile2.id}"] = distance(tile1.s, tile2.n)
        map["#{tile2.id}v#{tile1.id}"] = distance(tile2.s, tile1.n)
    return map
  window.map = map = buildMap()

  window.move = move = (coord, direction) ->
    bits = String(coord).split('.')
    switch direction
      when "n" then --bits[1]
      when "s" then ++bits[1]
      when "e" then ++bits[0]
      when "w" then --bits[0]
    return bits.join('.')

  # less efficient, but more readable
  buildReverseResultGrid = (input) ->
    output = {}
    for own key, value of input
      output[value] = key
    return output

  resultGrid = {}
  reverseResultGrid = {}
  placedTiles = []

  _inner = ->
    # find the closest match
    matchDistance = 9999
    match = ""
    mapFilterRe = new RegExp("(#{placedTiles.join(")|(")})".replace(/\./g, "\\."))
    for own testMatch, testMatchDistance of map
      if mapFilterRe.test(testMatch) and testMatchDistance < matchDistance
        matchDistance = testMatchDistance
        match = testMatch
    console.log "step #{stepNumber} match:", match

    # place matching tile(s)
    matchPair = match.split(/[vh]/)
    matchPairOrientation = if match.indexOf('v') != -1 then "v" else "h"
    if !placedTiles.length  # this is our first time through the loop
      origin = '0.0'
      resultGrid[origin] = matchPair[0]
      reverseResultGrid = buildReverseResultGrid(resultGrid)
    console.log "map.length", Object.getOwnPropertyNames(map).length
    a = matchPair[0]
    b = matchPair[1]
    if origin = reverseResultGrid[a]
      toBePlaced = b
      if matchPairOrientation == "v"
        resultGrid[move(origin, "s")] = b
      else
        resultGrid[move(origin, "e")] = b
    else if origin = reverseResultGrid[b]
      toBePlaced = a
      if matchPairOrientation == "v"
        resultGrid[move(origin, "n")] = a
      else
        resultGrid[move(origin, "w")] = a
    else
      console.error "oops, incorrectly matched a disjoint tile"
      return resultGrid

    # cleanup and setup for the next run through the loop
    window.resultGrid = resultGrid
    window.reverseResultGrid = reverseResultGrid = buildReverseResultGrid(resultGrid)
    placedTiles = Object.keys(reverseResultGrid)
    # eliminate all invalid matches
    for own key, value of map
      if key.startsWith("#{a}#{matchPairOrientation}")
        delete map[key]
        continue
      if key.endsWith("#{matchPairOrientation}#{b}")
        delete map[key]
        continue
      matchPair = key.split(/[vh]/)
      # remove already placed tiles
      if matchPair[0] in placedTiles and matchPair[1] in placedTiles
        delete map[key]
        continue
    # check the other orientation of `toBePlaced`
    # TODO this block could be executed smarter
    if resultGrid[move(reverseResultGrid[toBePlaced], "e")]
      console.log "!!!Delete east of #{toBePlaced}"
      for own key, value of map
        if key.startsWith("#{toBePlaced}h")
          delete map[key]
          continue
    if resultGrid[move(reverseResultGrid[toBePlaced], "s")]
      console.log "!!!Delete south of #{toBePlaced}"
      for own key, value of map
        if key.startsWith("#{toBePlaced}v")
          delete map[key]
          continue
    if resultGrid[move(reverseResultGrid[toBePlaced], "n")]
      console.log "!!!Delete north of #{toBePlaced}"
      for own key, value of map
        if key.endsWith("v#{toBePlaced}")
          delete map[key]
          continue
    if resultGrid[move(reverseResultGrid[toBePlaced], "w")]
      console.log "!!!Delete west of #{toBePlaced}"
      for own key, value of map
        if key.endsWith("h#{toBePlaced}")
          delete map[key]
          continue
    console.log "map.length",
                Object.getOwnPropertyNames(map).length,
                copy(map),
    drawGrid(resultGrid)

  # for stepNumber in [1..11]
  for stepNumber in [1..(n_slices * n_slices - 1)]
    setTimeout(_inner, stepNumber * 100)



  return resultGrid


# test if the result grid is a valid solution
resultIsValid = (resultGrid) ->
  dim = shape(resultGrid)
  return dim[0] <= n_slices and dim[1] <= n_slices


drawGrid = (grid, srcImg=_srcImg, dstCanvas=_dstCanvas) ->
  width = height = img.width
  # clear canvas, resize if necessary
  dim = shape(grid)
  dstCanvas.width = width * dim[0] / n_slices
  dstCanvas.height = height * dim[1] / n_slices
  c = dstCanvas.getContext("2d")
  # c.clearRect(0, 0, canvas.width, canvas.height)  # alternate

  # draw unscrambled image
  mapping = normalizeResultGrid grid
  for own dTile, sTile of mapping
    sBits = sTile.split('.')
    dBits = dTile.split('.')
    c.drawImage(srcImg,
      sBits[0] * slice_w, sBits[1] * slice_w, slice_w, slice_w,
      dBits[0] * slice_w, dBits[1] * slice_w, slice_w, slice_w)

# scope hack
_srcImg = ""
_dstCanvas = ""

main = ->
  _srcImg = img = $('img')
  width = height = img.width
  slice_w = width / n_slices

  _dstCanvas = canvas = $('canvas')
  c = canvas.getContext("2d")
  c.drawImage(img, 0, 0, width, height)

  imageData = c.getImageData(0, 0, width, height)
  edgeData = getAllEdgeData imageData.data

  _retries = retries
  resultGrid = getResult2(edgeData)
  while _retries-- and !resultIsValid(resultGrid)
    console.log "try again, attempt ##{retries - _retries}"
    resultGrid = getResult2(edgeData)

  # drawGrid(resultGrid)



# $(window).load(->
main()
# )
