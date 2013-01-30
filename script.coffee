# CONFIGURATION
n_slices = 4

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


# get the accumulated difference between two arrays
difference = (d1, d2) ->
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
      currentMatches.push([difference(targetSlice.n, data.s), data.id, "n"])
    allMatches.push(currentMatches.sort(bestMatchSort)[0])
  if "s" in edges
    # find south match
    currentMatches = []
    for data in edgeData
      currentMatches.push([difference(targetSlice.s, data.n), data.id, "s"])
    allMatches.push(currentMatches.sort(bestMatchSort)[0])
  if "e" in edges
    # find east match
    currentMatches = []
    for data in edgeData
      currentMatches.push([difference(targetSlice.e, data.w), data.id, "e"])
    allMatches.push(currentMatches.sort(bestMatchSort)[0])
  if "w" in edges
    # find west match
    currentMatches = []
    for data in edgeData
      currentMatches.push([difference(targetSlice.w, data.e), data.id, "w"])
    allMatches.push(currentMatches.sort(bestMatchSort)[0])

  bestMatch = allMatches.sort(bestMatchSort)[0]


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

main = ->
  img = $('img')
  width = img.width
  slice_w = width / n_slices

  canvas = $('canvas')
  c = canvas.getContext("2d")
  c.drawImage(img, 0, 0, 240, 240)

  imageData = c.getImageData(0, 0, canvas.width, canvas.height)
  edgeData = []

  slices = new Array(n_slices * n_slices)
  for num, i in slices
    row = Math.floor(i / n_slices)
    col = i % n_slices
    edgeData.push getEdgeData(imageData.data, row, col)

  # attempt 1, the long, stupid, dirty way

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

  threshold = 500  # match threshold, difference should be under this
  giveUpThreshold = 50 # give up after this many iterations

  while edgeData.length and (giveUpThreshold-- > 0)
    console.log "Iteration Start", placedTiles.length, giveUpThreshold
    attempts = 15
    neighbor = null
    console.log "Looking for neighbor for scrambled #{start.id} in directions #{validEdges(reverseResultGrid[start.id], resultGrid)}"
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
    console.log "Neighbor found", neighbor
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
      console.log "oops, solved #{solvedCoord} is already taken by #{resultGrid[solvedCoord]}"
      giveUpThreshold = -1  # give up

  console.log "finished with #{edgeData.length} left and #{giveUpThreshold}"
  mapping = normalizeResultGrid resultGrid

  c.clearRect(0, 0, canvas.width, canvas.height)
  canvas.width = canvas.width * 1.5
  canvas.height = canvas.height * 1.5
  for own dTile, sTile  of mapping
    sBits = sTile.split('.')
    dBits = dTile.split('.')
    c.drawImage(img, sBits[0] * slice_w, sBits[1] * slice_w, slice_w, slice_w,
      dBits[0] * slice_w, dBits[1] * slice_w, slice_w, slice_w)




    # console.log row * slice_w, col * slice_w




# $(window).load(->
main()
# )
