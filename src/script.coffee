# CONFIGURATION
defaultOptions =
  draw_delay: 0
  retries: 0
n_slices = 4
vignette_fix = 1  # black levels below this will have noise artificially added

# coffeescript scope hack
slice_w = 0
_width = 0
_srcImg = ""
_dstCanvas = ""
_options = {}


# ###Interacting with a pixel array

# Get the color information about a coordinate `x`, `y` in pixel array `d`.
# Instead of using RGB from the raw data, use LAB by default since working in a
# colorspace that mimics human perception yields better results.
getPixel = (d, x, y) ->
  index = (x + y * _width) * 4
  rgb =
    r: d[index]
    g: d[index + 1]
    b: d[index + 2]
  lab = Color.convert(rgb, "lab")
  if lab.l < vignette_fix
    lab.l = Math.floor(Math.random() * 100)
  return lab


# For debugging, replace `getPixel` with this to see which pixels are actually
# getting touched by `getPixel`.
setPixel = (d, x, y) ->
  index = (x + y * _width) * 4
  rgba = [d[index], d[index + 1], d[index + 2], d[index + 3]]
  d[index] = 0
  d[index + 1] = 0
  d[index + 2] = 0
  return d


# Get the top `n`, right `e`, bottom `s`, and left `w` description of a slice
# of imageData `d`.
getEdgeData = (d, x, y) ->
  x_begin = x * slice_w
  x_end = x_begin + slice_w - 1
  y_begin = y * slice_w
  y_end = y_begin + slice_w - 1
  data =
    id: "#{x}.#{y}"
    grid:
      x: x
      y: y
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


getEdgeComplexity = (edge) ->
  # quantitize array using bitshifting
  # only look at luminance (L) channel
  simplified = (x.l>>3 for x in edge)
  entropy = 0
  last = undefined
  for x in simplified
    if x != last
      # TODO add more entropy for bigger jumps
      entropy += 1
      last = x
  # entropy will be >= 1
  return entropy


# get the distance between two edges
distance = (d1, d2) ->
  sum = 0
  entropy1 = getEdgeComplexity(d1)
  entropy2 = getEdgeComplexity(d2)
  for color1, idx in d1
    color2 = d2[idx]
    sum += Math.pow(color2.l - color1.l, 2)
    sum += Math.pow(color2.a - color1.a, 2)
    sum += Math.pow(color2.b - color1.b, 2)
  return Math.sqrt sum / entropy1 / entropy2


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


# test if the result grid is a valid solution
resultIsValid = (resultGrid) ->
  dim = shape(resultGrid)
  return dim[0] <= n_slices and dim[1] <= n_slices


drawGrid = (grid, srcImg=_srcImg, dstCanvas=_dstCanvas) ->
  height = _width
  # clear canvas, resize if necessary
  dim = shape(grid)
  dstCanvas.width = _width * dim[0] / n_slices
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


exports = this


exports.descrambleImg = (img, options) ->
  extend _options, defaultOptions
  extend _options, options
  _srcImg = img
  _width = height = img.naturalWidth
  slice_w = _width / n_slices

  _dstCanvas = canvas = document.createElement('canvas');
  canvas.width = _width
  canvas.height = height
  c = canvas.getContext("2d")
  c.drawImage(img, 0, 0, _width, height)

  imageData = c.getImageData(0, 0, _width, height)
  edgeData = getAllEdgeData imageData.data

  resultGrid = getResult2(edgeData)
  retries_counter = _options.retries
  while retries_counter-- and !resultIsValid(resultGrid)
    console.log "try again, attempt ##{_options.retries - retries_counter}"
    resultGrid = getResult2(edgeData)

  if !_options.draw_delay
    drawGrid(resultGrid)
  return canvas


exports.main = ->
  img = $('img')
  canvas = descrambleImg(img)
  $('canvas-container').appendChild(canvas)
  $('go').onclick = ->
    $('canvas-container').removeChild(canvas)
    canvas = descrambleImg(img, {
        draw_delay: 500
      })
    $('canvas-container').appendChild(canvas)
