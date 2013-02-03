// Generated by CoffeeScript 1.4.0
(function() {
  var $, copy, defaultOptions, distance, drawGrid, exports, extend, getAllEdgeData, getEdgeComplexity, getEdgeData, getPixel, getResult2, n_slices, normalizeResultGrid, resultIsValid, retries, setPixel, shape, slice_w, vignette_fix, width, _dstCanvas, _options, _srcImg,
    __hasProp = {}.hasOwnProperty,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  $ = function(s) {
    return document.getElementById(s);
  };

  if (!String.prototype.startsWith) {
    String.prototype.startsWith = function(s) {
      return this.substring(0, s.length) === s;
    };
  }

  if (!String.prototype.endsWith) {
    String.prototype.endsWith = function(s) {
      return this.substring(this.length - s.length) === s;
    };
  }

  copy = function(o) {
    var k, r, v;
    r = {};
    for (k in o) {
      v = o[k];
      r[k] = v;
    }
    return r;
  };

  extend = function(object, properties) {
    var key, val;
    for (key in properties) {
      val = properties[key];
      object[key] = val;
    }
    return object;
  };

  getResult2 = function(tiles) {
    var buildMap, buildReverseResultGrid, delay, map, move, placedTiles, resultGrid, reverseResultGrid, stepNumber, _i, _inner, _inner_iteration_count, _ref;
    delay = _options.draw_delay;
    buildMap = function() {
      var i, map, tile1, tile2, _i, _j, _len, _len1, _ref;
      map = {};
      for (i = _i = 0, _len = tiles.length; _i < _len; i = ++_i) {
        tile1 = tiles[i];
        _ref = tiles.slice(i + 1);
        for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
          tile2 = _ref[_j];
          map["" + tile1.id + "h" + tile2.id] = distance(tile1.w, tile2.e);
          map["" + tile2.id + "h" + tile1.id] = distance(tile2.w, tile1.e);
          map["" + tile1.id + "v" + tile2.id] = distance(tile1.s, tile2.n);
          map["" + tile2.id + "v" + tile1.id] = distance(tile2.s, tile1.n);
        }
      }
      return map;
    };
    window.map = map = buildMap();
    window.move = move = function(coord, direction) {
      var bits;
      bits = String(coord).split('.');
      switch (direction) {
        case "n":
          --bits[1];
          break;
        case "s":
          ++bits[1];
          break;
        case "e":
          ++bits[0];
          break;
        case "w":
          --bits[0];
      }
      return bits.join('.');
    };
    buildReverseResultGrid = function(input) {
      var key, output, value;
      output = {};
      for (key in input) {
        if (!__hasProp.call(input, key)) continue;
        value = input[key];
        output[value] = key;
      }
      return output;
    };
    resultGrid = {};
    reverseResultGrid = {};
    placedTiles = [];
    _inner_iteration_count = 0;
    _inner = function() {
      var a, b, key, mapFilterRe, match, matchDistance, matchPair, matchPairOrientation, origin, testMatch, testMatchDistance, toBePlaced, value, _ref, _ref1;
      matchDistance = 9999;
      match = "";
      mapFilterRe = new RegExp(("(" + (placedTiles.join(")|(")) + ")").replace(/\./g, "\\."));
      for (testMatch in map) {
        if (!__hasProp.call(map, testMatch)) continue;
        testMatchDistance = map[testMatch];
        if (mapFilterRe.test(testMatch) && testMatchDistance < matchDistance) {
          matchDistance = testMatchDistance;
          match = testMatch;
        }
      }
      console.log("step " + (++_inner_iteration_count) + " match:", match);
      matchPair = match.split(/[vh]/);
      matchPairOrientation = match.indexOf('v') !== -1 ? "v" : "h";
      if (!placedTiles.length) {
        origin = '0.0';
        resultGrid[origin] = matchPair[0];
        reverseResultGrid = buildReverseResultGrid(resultGrid);
      }
      console.log("map.length", Object.getOwnPropertyNames(map).length);
      a = matchPair[0];
      b = matchPair[1];
      if (origin = reverseResultGrid[a]) {
        toBePlaced = b;
        if (matchPairOrientation === "v") {
          resultGrid[move(origin, "s")] = b;
        } else {
          resultGrid[move(origin, "e")] = b;
        }
      } else if (origin = reverseResultGrid[b]) {
        toBePlaced = a;
        if (matchPairOrientation === "v") {
          resultGrid[move(origin, "n")] = a;
        } else {
          resultGrid[move(origin, "w")] = a;
        }
      } else {
        console.error("oops, incorrectly matched a disjoint tile");
        return resultGrid;
      }
      window.resultGrid = resultGrid;
      window.reverseResultGrid = reverseResultGrid = buildReverseResultGrid(resultGrid);
      placedTiles = Object.keys(reverseResultGrid);
      for (key in map) {
        if (!__hasProp.call(map, key)) continue;
        value = map[key];
        if (key.startsWith("" + a + matchPairOrientation)) {
          delete map[key];
          continue;
        }
        if (key.endsWith("" + matchPairOrientation + b)) {
          delete map[key];
          continue;
        }
        matchPair = key.split(/[vh]/);
        if ((_ref = matchPair[0], __indexOf.call(placedTiles, _ref) >= 0) && (_ref1 = matchPair[1], __indexOf.call(placedTiles, _ref1) >= 0)) {
          delete map[key];
          continue;
        }
      }
      if (resultGrid[move(reverseResultGrid[toBePlaced], "e")]) {
        console.log("!!!Delete east of " + toBePlaced);
        for (key in map) {
          if (!__hasProp.call(map, key)) continue;
          value = map[key];
          if (key.startsWith("" + toBePlaced + "h")) {
            delete map[key];
            continue;
          }
        }
      }
      if (resultGrid[move(reverseResultGrid[toBePlaced], "s")]) {
        console.log("!!!Delete south of " + toBePlaced);
        for (key in map) {
          if (!__hasProp.call(map, key)) continue;
          value = map[key];
          if (key.startsWith("" + toBePlaced + "v")) {
            delete map[key];
            continue;
          }
        }
      }
      if (resultGrid[move(reverseResultGrid[toBePlaced], "n")]) {
        console.log("!!!Delete north of " + toBePlaced);
        for (key in map) {
          if (!__hasProp.call(map, key)) continue;
          value = map[key];
          if (key.endsWith("v" + toBePlaced)) {
            delete map[key];
            continue;
          }
        }
      }
      if (resultGrid[move(reverseResultGrid[toBePlaced], "w")]) {
        console.log("!!!Delete west of " + toBePlaced);
        for (key in map) {
          if (!__hasProp.call(map, key)) continue;
          value = map[key];
          if (key.endsWith("h" + toBePlaced)) {
            delete map[key];
            continue;
          }
        }
      }
      console.log("map.length", Object.getOwnPropertyNames(map).length, copy(map));
      if (delay) {
        return drawGrid(resultGrid);
      }
    };
    for (stepNumber = _i = 1, _ref = n_slices * n_slices - 1; 1 <= _ref ? _i <= _ref : _i >= _ref; stepNumber = 1 <= _ref ? ++_i : --_i) {
      if (delay) {
        setTimeout(_inner, stepNumber * _options.draw_delay);
      } else {
        _inner();
      }
    }
    return resultGrid;
  };

  defaultOptions = {
    draw_delay: 0
  };

  n_slices = 4;

  retries = 0;

  vignette_fix = 1;

  slice_w = 0;

  width = 0;

  _srcImg = "";

  _dstCanvas = "";

  _options = {};

  getPixel = function(d, x, y) {
    var index, lab, rgb;
    index = (x + y * width) * 4;
    rgb = {
      r: d[index],
      g: d[index + 1],
      b: d[index + 2]
    };
    lab = Color.convert(rgb, "lab");
    if (lab.l < vignette_fix) {
      lab.l = Math.floor(Math.random() * 100);
    }
    return lab;
  };

  setPixel = function(d, x, y) {
    var index, rgba;
    index = (x + y * width) * 4;
    rgba = [d[index], d[index + 1], d[index + 2], d[index + 3]];
    d[index] = 0;
    d[index + 1] = 0;
    d[index + 2] = 0;
    return d;
  };

  getEdgeData = function(d, x, y) {
    var data, i, j, x_begin, x_end, y_begin, y_end, _i, _j;
    x_begin = x * slice_w;
    x_end = x_begin + slice_w - 1;
    y_begin = y * slice_w;
    y_end = y_begin + slice_w - 1;
    data = {
      id: "" + x + "." + y,
      grid: {
        x: x,
        y: y
      },
      n: [],
      s: [],
      e: [],
      w: []
    };
    for (i = _i = x_begin; x_begin <= x_end ? _i <= x_end : _i >= x_end; i = x_begin <= x_end ? ++_i : --_i) {
      data.n.push(getPixel(d, i, y_begin));
      data.s.push(getPixel(d, i, y_end));
    }
    for (j = _j = y_begin; y_begin <= y_end ? _j <= y_end : _j >= y_end; j = y_begin <= y_end ? ++_j : --_j) {
      data.e.push(getPixel(d, x_begin, j));
      data.w.push(getPixel(d, x_end, j));
    }
    return data;
  };

  getEdgeComplexity = function(edge) {
    var entropy, last, simplified, x, _i, _len;
    simplified = (function() {
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = edge.length; _i < _len; _i++) {
        x = edge[_i];
        _results.push(x.l >> 3);
      }
      return _results;
    })();
    entropy = 0;
    last = void 0;
    for (_i = 0, _len = simplified.length; _i < _len; _i++) {
      x = simplified[_i];
      if (x !== last) {
        entropy += 1;
        last = x;
      }
    }
    return entropy;
  };

  distance = function(d1, d2) {
    var color1, color2, entropy1, entropy2, idx, sum, _i, _len;
    sum = 0;
    entropy1 = getEdgeComplexity(d1);
    entropy2 = getEdgeComplexity(d2);
    for (idx = _i = 0, _len = d1.length; _i < _len; idx = ++_i) {
      color1 = d1[idx];
      color2 = d2[idx];
      sum += Math.pow(color2.l - color1.l, 2);
      sum += Math.pow(color2.a - color1.a, 2);
      sum += Math.pow(color2.b - color1.b, 2);
    }
    return Math.sqrt(sum / entropy1 / entropy2);
  };

  normalizeResultGrid = function(input) {
    var bits, key, minX, minY, newObj, value;
    minX = 99;
    minY = 99;
    for (key in input) {
      if (!__hasProp.call(input, key)) continue;
      bits = key.split('.');
      minX = Math.min(minX, bits[0]);
      minY = Math.min(minY, bits[1]);
    }
    newObj = {};
    for (key in input) {
      if (!__hasProp.call(input, key)) continue;
      value = input[key];
      bits = key.split('.');
      newObj["" + (bits[0] - minX) + "." + (bits[1] - minY)] = value;
    }
    return newObj;
  };

  shape = function(input) {
    var bits, key, maxX, maxY, minX, minY;
    minX = 99;
    minY = 99;
    maxX = -99;
    maxY = -99;
    for (key in input) {
      if (!__hasProp.call(input, key)) continue;
      bits = key.split('.');
      minX = Math.min(minX, bits[0]);
      maxX = Math.max(maxX, bits[0]);
      minY = Math.min(minY, bits[1]);
      maxY = Math.max(maxY, bits[1]);
    }
    return [maxX - minX + 1, maxY - minY + 1];
  };

  getAllEdgeData = function(imageDataArray) {
    var col, edgeData, i, num, row, slices, _i, _len;
    edgeData = [];
    slices = new Array(n_slices * n_slices);
    for (i = _i = 0, _len = slices.length; _i < _len; i = ++_i) {
      num = slices[i];
      row = Math.floor(i / n_slices);
      col = i % n_slices;
      edgeData.push(getEdgeData(imageDataArray, row, col));
    }
    return edgeData;
  };

  resultIsValid = function(resultGrid) {
    var dim;
    dim = shape(resultGrid);
    return dim[0] <= n_slices && dim[1] <= n_slices;
  };

  drawGrid = function(grid, srcImg, dstCanvas) {
    var c, dBits, dTile, dim, height, mapping, sBits, sTile, _results;
    if (srcImg == null) {
      srcImg = _srcImg;
    }
    if (dstCanvas == null) {
      dstCanvas = _dstCanvas;
    }
    width = height = img.width;
    dim = shape(grid);
    dstCanvas.width = width * dim[0] / n_slices;
    dstCanvas.height = height * dim[1] / n_slices;
    c = dstCanvas.getContext("2d");
    mapping = normalizeResultGrid(grid);
    _results = [];
    for (dTile in mapping) {
      if (!__hasProp.call(mapping, dTile)) continue;
      sTile = mapping[dTile];
      sBits = sTile.split('.');
      dBits = dTile.split('.');
      _results.push(c.drawImage(srcImg, sBits[0] * slice_w, sBits[1] * slice_w, slice_w, slice_w, dBits[0] * slice_w, dBits[1] * slice_w, slice_w, slice_w));
    }
    return _results;
  };

  exports = this;

  exports.descrambleImg = function(img, options) {
    var c, canvas, edgeData, height, imageData, resultGrid, _retries;
    extend(_options, defaultOptions);
    extend(_options, options);
    _srcImg = img;
    width = height = img.width;
    slice_w = width / n_slices;
    _dstCanvas = canvas = document.createElement('canvas');
    canvas.width = width;
    canvas.height = height;
    c = canvas.getContext("2d");
    c.drawImage(img, 0, 0, width, height);
    imageData = c.getImageData(0, 0, width, height);
    edgeData = getAllEdgeData(imageData.data);
    _retries = retries;
    resultGrid = getResult2(edgeData);
    while (_retries-- && !resultIsValid(resultGrid)) {
      console.log("try again, attempt #" + (retries - _retries));
      resultGrid = getResult2(edgeData);
    }
    if (!_options.draw_delay) {
      drawGrid(resultGrid);
    }
    return canvas;
  };

  exports.main = function() {
    var canvas, img;
    img = $('img');
    canvas = descrambleImg(img);
    $('canvas-container').appendChild(canvas);
    return $('go').onclick = function() {
      $('canvas-container').removeChild(canvas);
      canvas = descrambleImg(img, {
        draw_delay: 500
      });
      return $('canvas-container').appendChild(canvas);
    };
  };

}).call(this);
