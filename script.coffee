n_slices = 4
slice_w = 0
width = 0

getPixel = (d, x, y) ->
  index = (x + y * width) * 4
  rgba = [d[index], d[index + 1], d[index + 2], d[index + 3]]
  # only use green channel for now
  return rgba

setPixel = (d, x, y) ->
  index = (x + y * width) * 4
  rgba = [d[index], d[index + 1], d[index + 2], d[index + 3]]
  # console.log rgba
  d[index] = 0
  d[index + 1] = 0
  d[index + 2] = 0
  return d

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
  for value, i in d1
    sum += Math.abs(d2[i][1] - value[1])
  return sum


# for Array.sort
bestMatchSort = (a, b) -> a[0] - b[0]


findNeighbor = (start, edgeData)->
  allMatches = []
  # find north match
  currentMatches = []
  for data in edgeData
    currentMatches.push([difference(start.n, data.s), data.id, "n"])
  allMatches.push(currentMatches.sort(bestMatchSort)[0])
  # find south match
  currentMatches = []
  for data in edgeData
    currentMatches.push([difference(start.s, data.n), data.id, "s"])
  allMatches.push(currentMatches.sort(bestMatchSort)[0])
  # find east match
  currentMatches = []
  for data in edgeData
    currentMatches.push([difference(start.e, data.w), data.id, "e"])
  allMatches.push(currentMatches.sort(bestMatchSort)[0])
  # find west match
  currentMatches = []
  for data in edgeData
    currentMatches.push([difference(start.w, data.e), data.id, "w"])
  allMatches.push(currentMatches.sort(bestMatchSort)[0])

  bestMatch = allMatches.sort(bestMatchSort)[0]


# make sure the top left is 0.0
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


main = ->
  img = $('img')[0]
  width = img.width
  slice_w = width / n_slices

  canvas = $('canvas')[0]
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
  resultGrid = {}
  reverseResultGrid = {}
  start = edgeData.pop()
  positionX = 0
  positionY = 0
  resultGrid["#{positionX}.#{positionY}"] = start.id
  reverseResultGrid[start.id] = "#{positionX}.#{positionY}"
  placedTiles = [start]

  threshold = 1000

  while edgeData.length
    console.log "Iteration Start", placedTiles.length
    attempts = 15
    neighbor = null
    while (neighbor = findNeighbor(start, edgeData, threshold))[0] > threshold
      # no neighbor meeting threshold found, pick a new start
      console.log "no neighbor meeting threshold found, pick a new start", neighbor
      start = placedTiles[Math.floor(Math.random() * placedTiles.length)]
      bits = reverseResultGrid[start.id].split('.')
      positionX = bits[0]
      positionY = bits[1]
      if !--attempts
        attempts = 15
        threshold = threshold * 1.1
        console.log "Raising threshold: #{threshold}"
      if threshold > 100000
        console.error "oops", findNeighbor(start, edgeData, threshold)
        return
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
    if !resultGrid["#{positionX}.#{positionY}"]
      edgeData = newEdgeData
      resultGrid["#{positionX}.#{positionY}"] = neighbor[1]
      reverseResultGrid[neighbor[1]] = "#{positionX}.#{positionY}"

  mapping = normalizeResultGrid resultGrid

  c.clearRect(0, 0, canvas.width, canvas.height)
  # canvas.width = canvas.width * 1.5
  # canvas.height = canvas.height * 1.5
  for own dTile, sTile  of mapping
    sBits = sTile.split('.')
    dBits = dTile.split('.')
    c.drawImage(img, sBits[0] * slice_w, sBits[1] * slice_w, slice_w, slice_w,
      dBits[0] * slice_w, dBits[1] * slice_w, slice_w, slice_w)




    # console.log row * slice_w, col * slice_w




$(window).load(->
  main()
)
