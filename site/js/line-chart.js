// A small SVG line chart, shared by the pages that draw one.  Years along the
// bottom, money up the side.
(function (root) {
  'use strict';

  var SVG = 'http://www.w3.org/2000/svg';

  function el(name, attrs, text) {
    var node = document.createElementNS(SVG, name);
    for (var k in attrs) node.setAttribute(k, attrs[k]);
    if (text !== undefined) node.textContent = text;
    return node;
  }

  // short labels for the axis: $625k, $2.5M
  function shortMoney(n) {
    if (n >= 1e6) return '$' + (Math.round(n / 1e5) / 10) + 'M';
    if (n >= 1e3) return '$' + Math.round(n / 1e3) + 'k';
    return '$' + Math.round(n);
  }

  // a step for the axis: 1, 2 or 5 times a power of ten, about 4 steps
  function niceStep(max) {
    var raw = max / 4;
    var p = Math.pow(10, Math.floor(Math.log(raw) / Math.LN10));
    var m = raw / p;
    return (m <= 1 ? 1 : m <= 2 ? 2 : m <= 5 ? 5 : 10) * p;
  }

  // o: {
  //   xMax, yMax, yFormat, xTitle, label (for screen readers),
  //   lines:  [{values: fn(t), cls}], drawn from 0 to o.xEnd,
  //   xEnd:   where the lines stop (default: o.retire, or xMax),
  //   gap:    {upper: fn(t), lower: fn(t), label} shades between two lines,
  //   ends:   [{value, label, below}] labels at the right end of the lines,
  //   goals:  [{value, label}] dashed lines across,
  //   retire: a year to mark with a green line, with retireText under "Retire",
  //   hover:  fn(year) -> {title, points: [{value, text, cls, dot}]} to show the
  //           values under the mouse, or where a finger taps or drags,
  //   picked: a year to show those values for when nothing's under the mouse,
  //   onPick: fn(year) called on a click or tap,
  // }
  function draw(box, o) {
    var width = Math.max(260, box.clientWidth || 400);
    var height = Math.round(Math.min(340, Math.max(240, width * .42)));
    var pad = { top: 14, right: 12, bottom: 34, left: 52 };
    var plotW = width - pad.left - pad.right;
    var plotH = height - pad.top - pad.bottom;
    var xMax = o.xMax;
    var xEnd = o.xEnd !== undefined ? o.xEnd : o.retire !== undefined ? o.retire : xMax;
    var yStep = niceStep(o.yMax);
    var yMax = Math.ceil(o.yMax * 1.08 / yStep) * yStep;
    var xx = function (t) { return pad.left + t / xMax * plotW; };
    var yy = function (v) { return pad.top + plotH - v / yMax * plotH; };
    var goals = o.goals || [];

    var svg = el('svg', { viewBox: '0 0 ' + width + ' ' + height, width: width, height: height });
    for (var v = 0; v <= yMax + 1e-9; v += yStep) {
      svg.appendChild(el('line', { class: 'grid', x1: pad.left, x2: width - pad.right, y1: yy(v), y2: yy(v) }));
      svg.appendChild(el('text', { class: 'tick', x: pad.left - 6, y: yy(v) + 4, 'text-anchor': 'end' }, o.yFormat(v)));
    }
    var xStep = xMax > 30 ? 10 : 5;
    for (var t = 0; t <= xMax; t += xStep) {
      svg.appendChild(el('text', { class: 'tick', x: xx(t), y: height - 16, 'text-anchor': 'middle' }, t));
    }
    svg.appendChild(el('text', { class: 'tick', x: pad.left + plotW / 2, y: height - 2, 'text-anchor': 'middle' }, o.xTitle));

    goals.forEach(function (g) {
      svg.appendChild(el('line', { class: 'goal', x1: pad.left, x2: width - pad.right, y1: yy(g.value), y2: yy(g.value) }));
    });

    var path = function (fn, from, to) {
      var d = '';
      for (var i = 0; i <= 60; i++) {
        var t = from + (to - from) * i / 60;
        d += (i ? 'L' : 'M') + xx(t).toFixed(1) + ' ' + yy(fn(t)).toFixed(1);
      }
      return d;
    };

    // the shaded space between two lines, labelled in its widest part
    if (o.gap) {
      var back = path(o.gap.lower, xEnd, 0).replace(/^M/, 'L');
      svg.appendChild(el('path', { class: 'gap', d: path(o.gap.upper, 0, xEnd) + back + 'Z' }));
    }

    if (o.retire !== undefined) {
      svg.appendChild(el('line', { class: 'retire', x1: xx(o.retire), x2: xx(o.retire), y1: pad.top, y2: pad.top + plotH }));
      // to the right of the line, or the left when it would run off the edge
      var fits = xx(o.retire) + 5 + 56 <= width;
      var at = { x: xx(o.retire) + (fits ? 5 : -5), 'text-anchor': fits ? 'start' : 'end' };
      svg.appendChild(el('text', { class: 'retire-label', x: at.x, y: pad.top + plotH - 20, 'text-anchor': at['text-anchor'] }, 'Retire'));
      svg.appendChild(el('text', { class: 'retire-label', x: at.x, y: pad.top + plotH - 6, 'text-anchor': at['text-anchor'] }, o.retireText));
    }

    o.lines.forEach(function (line) {
      svg.appendChild(el('path', { class: 'line ' + line.cls, d: path(line.values, 0, xEnd) }));
    });

    // labels last, so they sit on top of the lines
    // the gap's label sits in its bottom right corner, just above the lower
    // line, where the gap is widest.  left out when it wouldn't fit inside
    if (o.gap && o.gap.label) {
      var ly = yy(o.gap.lower(xEnd)) - 24;
      var left = xx(xEnd) - 4 - o.gap.label.length * 6.2;
      var leftT = (left - pad.left) / plotW * xMax;
      if (yy(o.gap.upper(leftT)) < ly - 14) {
        svg.appendChild(el('text', { class: 'gap-label', x: xx(xEnd) - 4, y: ly, 'text-anchor': 'end' }, o.gap.label));
      }
    }
    (o.ends || []).forEach(function (e) {
      svg.appendChild(el('text', { class: 'end-label ' + (e.cls || ''), x: xx(xEnd), y: yy(e.value) + (e.below ? 16 : -7),
                                   'text-anchor': 'end' }, e.label));
    });
    // goal labels sit right of the retire line, where the lines have
    // stopped, unless there isn't room
    goals.forEach(function (g) {
      var right = xx(o.retire) + 6 + g.label.length * 6.5 <= width - pad.right;
      svg.appendChild(el('text', { class: 'goal-label', x: xx(o.retire) + (right ? 6 : -6), y: yy(g.value) - 5,
                                   'text-anchor': right ? 'start' : 'end' }, g.label));
    });

    // drawn into on hover, on top of everything else
    var layer = el('g', { class: 'hover' });
    svg.appendChild(layer);

    box.innerHTML = '';
    box.appendChild(svg);
    box.setAttribute('role', 'img');
    box.setAttribute('aria-label', o.label);

    box._chart = { o: o, xx: xx, yy: yy, pad: pad, plotW: plotW, plotH: plotH, width: width, xMax: xMax, xEnd: xEnd, layer: layer };
    if (o.hover) {
      if (!box._wired) wire(box);
      showAt(box, box._year);  // keep showing the same year after a redraw
    }
  }

  // a rounded dark label.  anchor is where x is: 'start', 'middle' or 'end'
  function pill(x, y, text, anchor, width) {
    var w = text.length * 6.6 + 12;
    var left = anchor === 'end' ? x - w : anchor === 'middle' ? x - w / 2 : x;
    left = Math.max(0, Math.min(width - w, left));
    var g = el('g', { class: 'pill' });
    g.appendChild(el('rect', { x: left, y: y - 9, width: w, height: 18, rx: 4 }));
    g.appendChild(el('text', { x: left + w / 2, y: y + 4, 'text-anchor': 'middle' }, text));
    return g;
  }

  function showAt(box, year) {
    var c = box._chart;
    c.layer.replaceChildren();
    if (year === undefined || year === null) year = c.o.picked;
    var showing = year !== undefined && year !== null;
    if (showing) year = Math.max(c.o.hoverFrom || 0, Math.min(c.xEnd, year));
    if (!showing) {
      c.layer.ownerSVGElement.classList.remove('hovering');
      return;
    }
    var info = c.o.hover(year);
    var x = c.xx(year);
    // the fixed labels at the right end give way when the values reach them
    var widest = Math.max.apply(null, info.points.map(function (p) { return p.text.length * 6.6 + 12; }));
    c.layer.ownerSVGElement.classList.toggle('hovering', x + 10 + widest > c.xx(c.xEnd) - 60);
    c.layer.appendChild(el('line', { class: 'guide', x1: x, x2: x, y1: c.pad.top, y2: c.pad.top + c.plotH }));

    // values beside the dots: right of the guide, or left near the end.
    // bottom to top, kept clear of the year label and pushed up so they
    // don't overlap each other
    var right = x + 10 + 150 < c.width;
    var last = c.pad.top + c.plotH - 12 + 21;
    info.points.slice().sort(function (a, b) { return a.value - b.value; }).forEach(function (p) {
      var y = c.yy(p.value);
      if (p.dot !== false) c.layer.appendChild(el('circle', { class: 'dot ' + (p.cls || ''), cx: x, cy: y, r: 4.5 }));
      var ly = Math.min(y, last - 21);
      last = ly;
      c.layer.appendChild(pill(x + (right ? 10 : -10), ly, p.text, right ? 'start' : 'end', c.width));
    });
    c.layer.appendChild(pill(x, c.pad.top + c.plotH + 12, info.title, 'middle', c.width));
  }

  // mouse: follow it.  touch: show where the finger is and follow a drag
  // sideways, while up and down still scrolls the page
  function wire(box) {
    box._wired = true;
    box.classList.add('hoverable');
    var yearAt = function (clientX) {
      var c = box._chart;
      var rect = box.querySelector('svg').getBoundingClientRect();
      var px = (clientX - rect.left) * c.width / rect.width;
      return Math.round((px - c.pad.left) / c.plotW * c.xMax);
    };
    var move = function (e) {
      if (e.pointerType !== 'mouse' && !e.isPrimary) return;
      box._year = yearAt(e.clientX);
      showAt(box, box._year);
    };
    box.addEventListener('pointermove', function (e) {
      if (e.pointerType === 'mouse' || e.buttons) move(e);
    });
    box.addEventListener('pointerdown', move);
    box.addEventListener('click', function (e) {
      var c = box._chart;
      if (!c.o.onPick) return;
      var year = Math.max(c.o.hoverFrom || 0, Math.min(c.xEnd, yearAt(e.clientX)));
      box._year = null;
      c.o.onPick(year);
    });
    box.addEventListener('pointerleave', function (e) {
      if (e.pointerType !== 'mouse') return;
      box._year = null;
      showAt(box, null);
    });
  }

  root.LineChart = { draw: draw, niceStep: niceStep, shortMoney: shortMoney };
})(this);
