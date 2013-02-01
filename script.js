// Generated by CoffeeScript 1.4.0
(function() {
  var $, bestMatchSort, distance, drawGrid, findNeighbor, getAllEdgeData, getEdgeData, getPixel, getResult, getResult2, main, n_slices, normalizeResultGrid, resultIsValid, retries, setPixel, shape, slice_w, validEdges, vignette_fix, width,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
    __hasProp = {}.hasOwnProperty;

  n_slices = 4;

  vignette_fix = 0;

  retries = 0;

  slice_w = 0;

  width = 0;

  $ = function(s) {
    return document.getElementById(s);
  };

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

  getEdgeData = function(d, m, n) {
    var data, i, j, x_begin, x_end, y_begin, y_end, _i, _j;
    x_begin = m * slice_w;
    x_end = x_begin + slice_w - 1;
    y_begin = n * slice_w;
    y_end = y_begin + slice_w - 1;
    data = {
      id: "" + m + "." + n,
      grid: {
        m: m,
        n: n
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

  distance = function(d1, d2) {
    var color1, color2, idx, sum, _i, _len;
    sum = 0;
    for (idx = _i = 0, _len = d1.length; _i < _len; idx = ++_i) {
      color1 = d1[idx];
      color2 = d2[idx];
      sum += Math.pow(color2.l - color1.l, 2);
      sum += Math.pow(color2.a - color1.a, 2);
      sum += Math.pow(color2.b - color1.b, 2);
    }
    return Math.sqrt(sum);
  };

  bestMatchSort = function(a, b) {
    return a[0] - b[0];
  };

  findNeighbor = function(targetSlice, edgeData, edges) {
    var allMatches, bestMatch, currentMatches, data, _i, _j, _k, _l, _len, _len1, _len2, _len3;
    if (edges == null) {
      edges = "news";
    }
    allMatches = [];
    if (__indexOf.call(edges, "n") >= 0) {
      currentMatches = [];
      for (_i = 0, _len = edgeData.length; _i < _len; _i++) {
        data = edgeData[_i];
        currentMatches.push([distance(targetSlice.n, data.s), data.id, "n"]);
      }
      allMatches.push(currentMatches.sort(bestMatchSort)[0]);
    }
    if (__indexOf.call(edges, "s") >= 0) {
      currentMatches = [];
      for (_j = 0, _len1 = edgeData.length; _j < _len1; _j++) {
        data = edgeData[_j];
        currentMatches.push([distance(targetSlice.s, data.n), data.id, "s"]);
      }
      allMatches.push(currentMatches.sort(bestMatchSort)[0]);
    }
    if (__indexOf.call(edges, "e") >= 0) {
      currentMatches = [];
      for (_k = 0, _len2 = edgeData.length; _k < _len2; _k++) {
        data = edgeData[_k];
        currentMatches.push([distance(targetSlice.e, data.w), data.id, "e"]);
      }
      allMatches.push(currentMatches.sort(bestMatchSort)[0]);
    }
    if (__indexOf.call(edges, "w") >= 0) {
      currentMatches = [];
      for (_l = 0, _len3 = edgeData.length; _l < _len3; _l++) {
        data = edgeData[_l];
        currentMatches.push([distance(targetSlice.w, data.e), data.id, "w"]);
      }
      allMatches.push(currentMatches.sort(bestMatchSort)[0]);
    }
    return bestMatch = allMatches.sort(bestMatchSort)[0];
  };

  window.validEdge = validEdges = function(startCoord, resultGrid) {
    var bits, edges, x, y;
    bits = startCoord.split('.');
    x = +bits[0];
    y = +bits[1];
    edges = "";
    if (!resultGrid["" + x + "." + (y - 1)]) {
      edges += "n";
    }
    if (!resultGrid["" + x + "." + (y + 1)]) {
      edges += "s";
    }
    if (!resultGrid["" + (x - 1) + "." + y]) {
      edges += "e";
    }
    if (!resultGrid["" + (x + 1) + "." + y]) {
      edges += "w";
    }
    return edges;
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

  getResult = function(edgeData) {
    var attempts, giveUpThreshold, neighbor, newEdgeData, placedTiles, positionX, positionY, resultGrid, reverseResultGrid, solvedCoord, start, threshold, x, _i, _len;
    start = edgeData[Math.floor(Math.random() * edgeData.length)];
    edgeData = (function() {
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = edgeData.length; _i < _len; _i++) {
        x = edgeData[_i];
        if (x !== start) {
          _results.push(x);
        }
      }
      return _results;
    })();
    resultGrid = {};
    reverseResultGrid = {};
    positionX = 0;
    positionY = 0;
    resultGrid["" + positionX + "." + positionY] = start.id;
    reverseResultGrid[start.id] = "" + positionX + "." + positionY;
    placedTiles = [start];
    window.resultGrid = resultGrid;
    window.reverseResultGrid = reverseResultGrid;
    window.placedTiles = placedTiles;
    threshold = 500;
    giveUpThreshold = 50;
    while (edgeData.length && (giveUpThreshold-- > 0)) {
      attempts = 15;
      neighbor = null;
      neighbor = findNeighbor(start, edgeData, validEdges(reverseResultGrid[start.id], resultGrid));
      newEdgeData = [];
      for (_i = 0, _len = edgeData.length; _i < _len; _i++) {
        x = edgeData[_i];
        if (x.id === neighbor[1]) {
          start = x;
          placedTiles.push(x);
        } else {
          newEdgeData.push(x);
        }
      }
      switch (neighbor[2]) {
        case "n":
          positionY--;
          break;
        case "s":
          positionY++;
          break;
        case "e":
          positionX--;
          break;
        case "w":
          positionX++;
      }
      solvedCoord = "" + positionX + "." + positionY;
      if (!resultGrid[solvedCoord]) {
        edgeData = newEdgeData;
        resultGrid[solvedCoord] = neighbor[1];
        reverseResultGrid[neighbor[1]] = solvedCoord;
      } else {
        console.error("oops, solved " + solvedCoord + " is already taken by " + resultGrid[solvedCoord]);
        giveUpThreshold = -1;
      }
    }
    return resultGrid;
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

  getResult2 = function(tiles) {
    var buildMap, buildReverseResultGrid, key, map, mapFilterRe, match, matchDistance, matchPair, matchPairOrientation, move, origin, placedTiles, resultGrid, reverseResultGrid, stepNumber, testMatch, testMatchDistance, value, _i, _ref, _ref1, _ref2;
    buildMap = function() {
      var i, map, tile1, tile2, _i, _j, _len, _len1, _ref;
      map = {};
      for (i = _i = 0, _len = tiles.length; _i < _len; i = ++_i) {
        tile1 = tiles[i];
        _ref = tiles.slice(i + 1);
        for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
          tile2 = _ref[_j];
          map["" + tile1.id + "h" + tile2.id] = distance(tile1.e, tile2.w);
          map["" + tile2.id + "h" + tile1.id] = distance(tile2.e, tile1.w);
          map["" + tile1.id + "v" + tile2.id] = distance(tile1.s, tile2.n);
          map["" + tile2.id + "v" + tile1.id] = distance(tile2.s, tile1.n);
        }
      }
      return map;
    };
    window.map = map = buildMap();
    move = function(coord, direction) {
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
    for (stepNumber = _i = 1, _ref = n_slices * n_slices - 1; 1 <= _ref ? _i <= _ref : _i >= _ref; stepNumber = 1 <= _ref ? ++_i : --_i) {
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
      console.log("step " + stepNumber + " match:", match);
      matchPair = match.split(/[vh]/);
      matchPairOrientation = match.indexOf('v') !== -1 ? "v" : "h";
      if (!placedTiles.length) {
        origin = '0.0';
        resultGrid[origin] = matchPair[0];
        reverseResultGrid = buildReverseResultGrid(resultGrid);
      }
      console.log("map.length", Object.getOwnPropertyNames(map).length);
      if (origin = reverseResultGrid[matchPair[0]]) {
        if (matchPairOrientation === "v") {
          resultGrid[move(origin, "s")] = matchPair[1];
        } else {
          resultGrid[move(origin, "w")] = matchPair[1];
        }
      } else if (origin = reverseResultGrid[matchPair[1]]) {
        if (matchPairOrientation === "v") {
          resultGrid[move(origin, "n")] = matchPair[0];
        } else {
          resultGrid[move(origin, "e")] = matchPair[0];
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
        if (key.startsWith("" + matchPair[0] + matchPairOrientation)) {
          delete map[key];
          continue;
        }
        if (key.endsWith("" + matchPairOrientation + matchPair[1])) {
          delete map[key];
          continue;
        }
        matchPair = key.split(/[vh]/);
        if ((_ref1 = matchPair[0], __indexOf.call(placedTiles, _ref1) >= 0) && (_ref2 = matchPair[1], __indexOf.call(placedTiles, _ref2) >= 0)) {
          delete map[key];
          continue;
        }
      }
      console.log("map.length", Object.getOwnPropertyNames(map).length);
    }
    return resultGrid;
  };

  resultIsValid = function(resultGrid) {
    var dim;
    dim = shape(resultGrid);
    return dim[0] <= n_slices && dim[1] <= n_slices;
  };

  drawGrid = function(grid, srcImg, dstCanvas) {
    var c, dBits, dTile, dim, height, mapping, sBits, sTile, _results;
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

  main = function() {
    var c, canvas, edgeData, height, imageData, img, resultGrid, _retries;
    img = $('img');
    width = height = img.width;
    slice_w = width / n_slices;
    canvas = $('canvas');
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
    return drawGrid(resultGrid, img, canvas);
  };

  main();

}).call(this);
