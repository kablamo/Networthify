// The savings rate by country page.  Data: /data/household-saving.json,
// written by scripts/fetch-savings-data.py.
(function () {
  'use strict';

  var $ = function (id) { return document.getElementById(id); };

  var rates = [];       // [{name, value, row}] from the table in the page

  // === your savings rate, in the table ===

  function readTable() {
    var rows = document.querySelectorAll('#countryTable tbody tr');
    for (var i = 0; i < rows.length; i++) {
      var cells = rows[i].querySelectorAll('td');
      rates.push({ code: rows[i].getAttribute('data-code'), name: cells[0].textContent,
                   value: parseFloat(cells[2].textContent), row: rows[i] });
    }
  }

  function yourRate() {
    var v = String($('yourRate').value).replace(/[%,\s]/g, '');
    return v === '' || isNaN(v) ? null : Math.max(-100, Math.min(100, Number(v)));
  }

  // positions bars on one scale, with zero in the same place on every row.
  // scripts/fetch-savings-data.py does the same for the country table.
  function placer(values) {
    var lo = Math.min(0, Math.min.apply(null, values));
    var hi = Math.max(0, Math.max.apply(null, values));
    return function (node, v) {
      var zero = -lo / (hi - lo) * 100;
      var width = Math.abs(v) / (hi - lo) * 100;
      node.style.left = (v >= 0 ? zero : zero - width).toFixed(1) + '%';
      node.style.width = width.toFixed(1) + '%';
    };
  }

  function renderCompare() {
    var r = yourRate();
    renderWho();
    renderAge();
    var body = document.querySelector('#countryTable tbody');
    var you = body.querySelector('tr.you');
    if (you) you.parentNode.removeChild(you);

    // bars share one scale, yours included
    var values = rates.map(function (c) { return c.value; }).concat(r === null ? [] : [r]);
    var place = placer(values);
    rates.forEach(function (c) { place(c.row.querySelector('.bar'), c.value); });

    try {
      var url = r === null ? location.pathname : location.pathname + '?rate=' + r;
      history.replaceState(null, '', url);
    } catch (e) {}

    showRows();

    $('rateHint').hidden = r !== null;
    if (r === null) return;

    you = document.createElement('tr');
    you.className = 'you';
    you.innerHTML = '<td>You</td><td class="year"></td><td><span class="rate"><span class="track"><span class="bar"></span></span>' +
      '<span class="v"></span></span></td>';
    place(you.querySelector('.bar'), r);
    if (r < 0) you.querySelector('.bar').className = 'bar neg';
    you.querySelector('.v').textContent = r + '%';
    var after = rates.filter(function (c) { return c.value > r; }).pop();
    body.insertBefore(you, after ? after.row.nextSibling : body.firstChild);
    showRows();
  }

  // the table starts with the top ten.  your own row always shows.
  var TOP = 10;
  var showAll = false;

  function showRows() {
    rates.forEach(function (c, i) {
      c.row.hidden = !showAll && i >= TOP && c.code !== homeCode;
      c.row.classList.toggle('home', c.code === homeCode);
    });

    // mark each run of hidden rows, so a row below them doesn't look 11th
    var body = document.querySelector('#countryTable tbody');
    Array.prototype.slice.call(body.querySelectorAll('tr.gap')).forEach(function (g) { body.removeChild(g); });
    var rows = Array.prototype.slice.call(body.querySelectorAll('tr'));
    rows.forEach(function (row) {
      var prev = row.previousElementSibling;
      if (row.hidden || !prev || !prev.hidden) return;
      var skipped = 0;
      for (var p = prev; p && p.hidden; p = p.previousElementSibling) skipped++;
      var gap = document.createElement('tr');
      gap.className = 'gap';
      gap.innerHTML = '<td colspan="3"></td>';
      gap.firstChild.textContent = '⋯ ' + skipped + ' more';
      body.insertBefore(gap, row);
    });
    var btn = $('showAll');
    btn.hidden = rates.length <= TOP;
    btn.textContent = showAll ? 'Show the top ' + TOP + ' only' : 'Show all ' + rates.length + ' countries';
    btn.setAttribute('aria-expanded', String(showAll));
  }

  // === the visitor's country ===

  var homeCode = null;   // OECD code, e.g. USA

  // two-letter country codes to the OECD's three-letter ones.  smaller EU
  // members that the OECD doesn't list get the EU average.
  var ISO3 = {
    AT: 'AUT', AU: 'AUS', BE: 'BEL', CA: 'CAN', CL: 'CHL', CN: 'CHN', CO: 'COL',
    CZ: 'CZE', DE: 'DEU', DK: 'DNK', EE: 'EST', ES: 'ESP', FI: 'FIN', FR: 'FRA',
    GB: 'GBR', UK: 'GBR', GR: 'GRC', HU: 'HUN', IE: 'IRL', IT: 'ITA', JP: 'JPN',
    KR: 'KOR', LT: 'LTU', LU: 'LUX', LV: 'LVA', MX: 'MEX', NL: 'NLD', NZ: 'NZL',
    PL: 'POL', PT: 'PRT', SE: 'SWE', SK: 'SVK', US: 'USA', ZA: 'ZAF',
    BG: 'EU', CY: 'EU', HR: 'EU', MT: 'EU', RO: 'EU', SI: 'EU',
  };

  function rowFor(code) {
    return rates.filter(function (c) { return c.code === code; })[0];
  }

  function setHome(iso2) {
    var code = ISO3[String(iso2 || '').toUpperCase()];
    if (!code || !rowFor(code) || code === homeCode) return;
    homeCode = code;
    pickWhoCountry();
    renderCompare();
  }

  function findHome() {
    // a guess from the browser's language first (en-GB -> GB), then the
    // country Cloudflare sees, from its trace page on this same site
    var lang = (navigator.languages && navigator.languages[0]) || navigator.language || '';
    var m = /-([A-Za-z]{2})\b/.exec(lang);
    if (m) setHome(m[1]);
    if (!window.fetch) return;
    fetch('/cdn-cgi/trace')
      .then(function (res) { return res.ok ? res.text() : ''; })
      .then(function (text) {
        var loc = /^loc=([A-Z]{2})$/m.exec(text);
        if (loc) setHome(loc[1]);
      })
      .catch(function () {});
  }

  function setupCompare() {
    $('showAll').addEventListener('click', function () {
      showAll = !showAll;
      showRows();
      // collapsing from the bottom of a long list would leave you lost
      if (!showAll) $('latestTitle').scrollIntoView({ block: 'nearest' });
    });
    readTable();
    var input = $('yourRate');
    var fromUrl = new URLSearchParams(location.search).get('rate');
    if (fromUrl !== null && fromUrl !== '' && !isNaN(fromUrl)) input.value = fromUrl;
    input.addEventListener('input', renderCompare);
    renderCompare();
    findHome();
  }

  // === who saves: one bar per income fifth ===

  var fifths = {};

  // the income chart's "About this data" changes with the country's source
  var NOTES = {
    OECD: 'Gross saving as a share of gross disposable income, from the OECD\'s experimental ' +
          '<a href="https://data-explorer.oecd.org/vis?df[ag]=OECD.SDD.NAD&df[id]=DSD_EGDNA_INC_INC%40DF_INC_INC">distributional household accounts</a>.  Treat these as rough.',
    BLS: 'Households split into tenths by income before taxes.  Income after taxes minus spending, from the BLS ' +
         '<a href="https://www.bls.gov/cex/">Consumer Expenditure Survey</a>.  ' +
         'It counts pension contributions as spending, so these rates read a little low.',
  };

  // the same sideways bars as the country table.
  // rows: [{label, value, you}].
  // a few groups spend several times their income (US bottom tenth, -252%).
  // their bars stop at -100% with a break, or they'd squash every other bar.
  var FLOOR = -100;
  function barTable(box, caption, head, rows) {
    var place = placer(rows.map(function (b) { return Math.max(FLOOR, b.value); }));
    var table = document.createElement('table');
    table.className = 'rates';
    table.innerHTML = '<caption></caption><thead><tr><th></th><th>Savings rate</th></tr></thead><tbody></tbody>';
    table.querySelector('caption').textContent = caption;
    table.querySelector('th').textContent = head;
    rows.forEach(function (b) {
      var tr = document.createElement('tr');
      if (b.you) tr.className = 'you';
      tr.innerHTML = '<td></td><td><span class="rate"><span class="track"><span class="bar"></span></span>' +
        '<span class="v"></span></span></td>';
      tr.firstChild.textContent = b.label;
      var bar = tr.querySelector('.bar');
      if (b.value < 0) bar.className = b.value < FLOOR ? 'bar neg cut' : 'bar neg';
      place(bar, Math.max(FLOOR, b.value));
      tr.querySelector('.v').textContent = b.value + '%';
      table.tBodies[0].appendChild(tr);
    });
    box.innerHTML = '';
    box.appendChild(table);
  }

  function renderWho() {
    var c = fifths[$('whoCountry').value];
    if (!c) return;
    // fifths for most countries, tenths for the US
    var labels = c.values.length === 10
      ? ['Bottom 10%', '10–20%', '20–30%', '30–40%', '40–50%', '50–60%', '60–70%', '70–80%', '80–90%', 'Top 10%']
      : ['Bottom 20%', 'Lower middle', 'Middle', 'Upper middle', 'Top 20%'];
    $('whoNote').innerHTML = NOTES[c.source] || NOTES.OECD;

    // your rate is one more row, in order of size.  the groups save more
    // as income goes up, so they stay in income order.
    var r = yourRate();
    var bars = c.values.map(function (v, i) { return { value: v, label: labels[i] }; });
    if (r !== null) {
      var at = bars.filter(function (b) { return b.value <= r; }).length;
      bars.splice(at, 0, { value: r, label: 'You', you: true });
    }
    barTable($('whoChart'), c.name + ', ' + c.year + ', by household income', 'Income', bars);
  }

  // ages stay in order, so your rate goes first, not in order of size
  var byAge = null;

  function renderAge() {
    if (!byAge) return;
    var r = yourRate();
    var rows = byAge.groups.map(function (g) { return { value: g.value, label: g.label }; });
    if (r !== null) rows.unshift({ value: r, label: 'You', you: true });
    barTable($('ageChart'), 'United States, ' + byAge.year + ', by age', 'Age', rows);
  }

  // the income chart starts on the visitor's country, if it has one,
  // until they pick another
  var whoPicked = false;
  function pickWhoCountry() {
    if (whoPicked || !homeCode || !fifths[homeCode]) return;
    $('whoCountry').value = homeCode;
  }

  function setupWho(list) {
    var select = $('whoCountry');
    list.forEach(function (c) {
      fifths[c.code] = c;
      var o = document.createElement('option');
      o.value = c.code;
      o.textContent = c.name + ' (' + c.year + ')';
      select.appendChild(o);
    });
    select.value = fifths.FRA ? 'FRA' : list[0].code;
    pickWhoCountry();
    select.addEventListener('change', function () { whoPicked = true; renderWho(); });
  }

  function start(data) {
    setupWho(data.quintiles.countries);
    renderWho();
    byAge = data.age && data.age.countries[0];
    renderAge();
    renderCompare();
  }

  // the table is in the page, so comparing works before the data loads
  setupCompare();

  fetch('/data/household-saving.json')
    .then(function (res) { return res.json(); })
    .then(start)
    .catch(function () {
      $('whoChart').textContent = 'The chart could not load.';
    });
})();
