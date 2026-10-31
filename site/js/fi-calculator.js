// The early retirement calculator page: inputs, chart, big numbers, table.
(function () {
  'use strict';

  var M = window.FIMath;
  var $ = function (id) { return document.getElementById(id); };

  var DEFAULTS = { income: 50000, initialBalance: 0, expenses: 20000, annualPct: 5, withdrawalRate: 4 };
  var MONEY  = ['income', 'annualSavings', 'annualExpenses', 'initialBalance'];
  var PER_PERIOD = ['income', 'annualSavings', 'annualExpenses']; // shown per year or per month
  var FIELDS = ['income', 'annualSavings', 'annualExpenses', 'savingsRate', 'initialBalance', 'annualPct', 'withdrawalRate'];

  // the country markers on the chart (household savings rates in 2008)
  // household net saving, % of disposable income, latest year.  OECD.
  // same numbers as /savings-rate-by-country, rounded.  update them together.
  var COUNTRIES = [
    ['United Kingdom', 4], ['United States', 6], ['Germany', 10],
    ['France', 13], ['China', 35],
  ];

  var state = {};
  var hoverIndex = null;
  var touched = false;
  var period = 'annual'; // the money inputs are typed per year or per month

  // === state ===

  function readUrl() {
    var params = new URLSearchParams(window.location.search);
    var get = function (name) {
      var v = M.cleanNumber(params.get(name));
      // like the old site: missing or 0 means use the default
      return v ? v : DEFAULTS[name];
    };
    state.income         = get('income');
    state.initialBalance = get('initialBalance');
    state.annualExpenses = get('expenses');
    state.annualPct      = get('annualPct');
    state.withdrawalRate = get('withdrawalRate');
    state.annualSavings  = round2(state.income - state.annualExpenses);
    state.savingsRate    = rateFrom(state.annualSavings);
    return params.has('income');
  }

  function round2(n) { return Math.round(n * 100) / 100; }
  function rateFrom(savings) { return state.income > 0 ? (savings / state.income) * 100 : 0; }

  // when one input changes, update the ones that depend on it
  var recalculate = {
    income: function () {
      state.annualSavings = round2(state.income - state.annualExpenses);
      state.savingsRate   = rateFrom(state.annualSavings);
    },
    annualSavings: function () {
      state.annualExpenses = round2(state.income - state.annualSavings);
      state.savingsRate    = rateFrom(state.annualSavings);
    },
    annualExpenses: function () {
      state.annualSavings = round2(state.income - state.annualExpenses);
      state.savingsRate   = rateFrom(state.annualSavings);
    },
    savingsRate: function () {
      state.annualExpenses = Math.round(state.income * (1 - state.savingsRate / 100));
      state.annualSavings  = round2(state.income - state.annualExpenses);
    },
    initialBalance: function () {},
    annualPct:      function () {},
    withdrawalRate: function () {},
  };

  function validate(name, value) {
    if (isNaN(value)) return 'required';
    if (name === 'income' && value <= 0) return 'must be more than 0';
    if (name === 'withdrawalRate' && value <= 0) return 'must be more than 0';
    if (name === 'annualPct' && value <= -100) return 'must be more than -100';
    return '';
  }

  // inputs the user typed in since we last recalculated
  var edited = {};

  // apply the inputs the user changed.  returns false if something is invalid.
  function syncFromInputs() {
    var ok = true;
    FIELDS.forEach(function (name) {
      var input = $(name);
      var error = validate(name, M.cleanNumber(input.value));
      $(name + 'Warning').textContent = error;
      input.setAttribute('aria-invalid', error ? 'true' : 'false');
      if (error) ok = false;
    });
    if (!ok) return false;

    FIELDS.forEach(function (name) {
      if (!edited[name]) return;
      state[name] = M.cleanNumber($(name).value) * perYear(name);
      recalculate[name]();
      touched = true;
    });
    edited = {};
    return true;
  }

  // === output ===

  function args() {
    return {
      income:         state.income,
      initialBalance: state.initialBalance,
      annualPct:      state.annualPct,
      withdrawalRate: state.withdrawalRate,
    };
  }

  function formatRate(rate) { return String(Math.round(rate * 10) / 10); }

  // the state is always annual.  this is what to multiply an input by.
  function perYear(name) {
    return period === 'monthly' && PER_PERIOD.indexOf(name) >= 0 ? 12 : 1;
  }

  function display(name) {
    if (name === 'savingsRate') return formatRate(state.savingsRate);
    return String(MONEY.indexOf(name) >= 0 ? round2(state[name] / perYear(name)) : state[name]);
  }

  function shareUrl() {
    var params = new URLSearchParams({
      income:         state.income,
      initialBalance: state.initialBalance,
      expenses:       state.annualExpenses,
      annualPct:      state.annualPct,
      withdrawalRate: state.withdrawalRate,
    });
    if (period === 'monthly') params.set('period', 'monthly');
    return '/calculator/earlyretirement?' + params.toString();
  }

  function render() {
    var years = M.yearsToFI(args(), state.savingsRate / 100);
    var shown = M.roundYears(years);

    FIELDS.forEach(function (name) { $(name).value = display(name); });
    PER_PERIOD.forEach(function (name) {
      $(name + 'Unit').textContent = period === 'monthly' ? '/mo' : '/yr';
    });

    var when = $('yearsToFIText').previousElementSibling;
    if (!isFinite(shown))  { when.textContent = 'You can retire in'; $('yearsToFIText').textContent = '∞ years'; }
    else if (shown === 0)  { when.textContent = 'You can retire'; $('yearsToFIText').textContent = 'now'; }
    else                   { when.textContent = 'You can retire in'; $('yearsToFIText').textContent = shown + ' years'; }

    $('savingsRateText').textContent     = formatRate(state.savingsRate) + '%';
    $('compareLink').href = '/savings-rate-by-country?rate=' + formatRate(state.savingsRate);
    $('goalText').textContent = M.toMoney(state.annualExpenses / (state.withdrawalRate / 100));
    $('goalExpensesText').textContent = period === 'monthly'
      ? M.toMoney(state.annualExpenses / 12) + ' a month'
      : M.toMoney(state.annualExpenses) + ' a year';
    $('goalRateText').textContent = state.withdrawalRate + '%';

    // with no savings the answer can still be finite.  say why, or it looks like a bug.
    var explain = $('explain');
    var coasting = state.annualSavings <= 0 && isFinite(shown) && shown > 0;
    explain.hidden = isFinite(years) && !coasting;
    explain.textContent = !isFinite(years)
      ? 'At this savings rate your net worth never grows enough to cover your expenses.'
      : 'Your $' + M.toMoney(state.initialBalance) + (state.annualSavings === 0
        ? ' grows enough on its own. No new savings needed.'
        : ' grows faster than you spend it down.');

    renderTable(years);
    renderChart();

    if (touched) {
      try { window.history.replaceState(null, '', shareUrl()); } catch (e) {}
    }
  }

  function renderTable(years) {
    var rows = M.yearByYear(args(), state.annualSavings, state.annualExpenses, years);
    var w = state.withdrawalRate;
    var money = M.toMoney;
    var html =
      '<thead><tr>' +
      '<th>End of year</th>' +
      '<th class="wide">Income</th>' +
      '<th class="wide">Expenses</th>' +
      '<th class="wide">' + state.annualPct + '% return on investments</th>' +
      '<th>Expenses covered by a ' + w + '% withdrawal</th>' +
      '<th>Change in net worth (savings + return)</th>' +
      '<th>Net worth</th>' +
      '</tr></thead><tbody>' +
      '<tr><td>0</td><td class="wide">-</td><td class="wide">-</td><td class="wide">-</td>' +
      '<td>-</td><td>-</td><td>' + money(state.initialBalance) + '</td></tr>';

    rows.forEach(function (row) {
      var pct = Math.round(row.covered * 100);
      var bar = Math.min(100, Math.max(0, pct));
      html +=
        '<tr' + (row.fi ? ' class="fi"' : '') + '>' +
        '<td>' + row.year + '</td>' +
        '<td class="wide">' + money(row.income) + '</td>' +
        '<td class="wide">' + money(row.expenses) + '</td>' +
        '<td class="wide">' + money(row.rturn) + '</td>' +
        '<td><div class="meter"><span class="track"><span class="bar" style="width:' + bar + '%"></span></span>' +
          '<span class="v">' + pct + '%</span></div></td>' +
        '<td>' + money(row.change) + '</td>' +
        '<td>' + money(row.networth) + '</td>' +
        '</tr>';
    });

    $('fi').innerHTML = html + '</tbody>';
  }

  // === chart ===

  var SVG = 'http://www.w3.org/2000/svg';
  var geometry = null;

  function el(name, attrs, text) {
    var node = document.createElementNS(SVG, name);
    for (var k in attrs) node.setAttribute(k, attrs[k]);
    if (text !== undefined) node.textContent = text;
    return node;
  }

  function niceStep(max, ticks) {
    var steps = [1, 2, 5, 10, 20, 25, 50, 100, 200, 500];
    for (var i = 0; i < steps.length; i++) if (max / steps[i] <= ticks) return steps[i];
    return Math.ceil(max / ticks);
  }

  // each bar is 2% of savings rate, or 5% on phones where 2% bars are too thin to tap
  var barStep = 2;
  function lastIndex() { return 100 / barStep; }
  function pickedIndex() { return Math.max(0, Math.min(lastIndex(), Math.round(state.savingsRate / barStep))); }

  function renderChart() {
    var box = $('chart');
    var width  = Math.max(280, box.clientWidth || 600);
    var height = width < 500 ? 270 : 300;
    var pad    = { top: 10, right: 8, bottom: 44, left: 58 };

    var bars = [];
    barStep = width < 500 ? 5 : 2;
    for (var i = 0; i <= 100; i += barStep) {
      bars.push({ rate: i, years: M.roundYears(M.yearsToFI(args(), i / 100)) });
    }
    var finite = bars.filter(function (b) { return isFinite(b.years); });
    var maxYears = Math.max(1, Math.max.apply(null, finite.map(function (b) { return b.years; })));
    var step = niceStep(maxYears, width < 500 ? 5 : 8);
    var top  = Math.ceil(maxYears / step) * step;

    var plotW = width - pad.left - pad.right;
    var plotH = height - pad.top - pad.bottom;
    var span = 100 + barStep; // half a bar of room at each end
    var x = function (rate)  { return pad.left + ((rate + barStep / 2) / span) * plotW; };
    var y = function (years) { return pad.top + plotH - (years / top) * plotH; };
    geometry = { x: x, pad: pad, plotW: plotW };

    var svg = el('svg', { viewBox: '0 0 ' + width + ' ' + height, width: width, height: height, 'aria-hidden': 'true' });

    // y axis grid and ticks
    for (var t = 0; t <= top; t += step) {
      var g = el('g', { class: 'tick' });
      g.appendChild(el('line', { class: 'grid', x1: pad.left, x2: pad.left + plotW, y1: y(t), y2: y(t) }));
      g.appendChild(el('text', { x: pad.left - 6, y: y(t) + 4, 'text-anchor': 'end' }, t));
      svg.appendChild(g);
    }
    var ty = pad.top + plotH / 2;
    svg.appendChild(el('text', { class: 'axis-title', x: 14, y: ty, 'text-anchor': 'middle', transform: 'rotate(-90 14 ' + ty + ')' }, 'Years to retirement'));

    // x axis ticks
    for (var r = 0; r <= 100; r += (width < 500 ? 20 : 10)) {
      var gx = el('g', { class: 'tick' });
      gx.appendChild(el('text', { x: x(r), y: pad.top + plotH + 16, 'text-anchor': 'middle' }, r + '%'));
      svg.appendChild(gx);
    }
    svg.appendChild(el('text', { class: 'axis-title', x: pad.left + plotW / 2, y: height - 6, 'text-anchor': 'middle' }, 'Savings rate'));

    // bars
    var picked = pickedIndex();
    var barW = (barStep / span) * plotW;
    bars.forEach(function (b, idx) {
      if (!isFinite(b.years)) return;
      var cls = 'bar' + (idx === picked ? ' pick' : '') + (idx === hoverIndex && idx !== picked ? ' hover' : '');
      svg.appendChild(el('rect', {
        class: cls, x: x(b.rate) - barW / 2, width: barW,
        y: y(b.years), height: Math.max(0, y(0) - y(b.years)),
      }));
    });

    svg.appendChild(el('rect', { class: 'axis', x: pad.left, y: pad.top, width: plotW, height: plotH }));

    // country markers, written bottom to top like the old chart.  they
    // overlap on phones, which list them under the chart instead.
    $('countryLegend').hidden = width >= 500;
    if (width >= 500) COUNTRIES.forEach(function (c) {
      var cx = x(c[1]) + 4;
      var cy = y(0) - 4;
      svg.appendChild(el('text', { class: 'country', x: cx, y: cy, transform: 'rotate(-90 ' + cx + ' ' + cy + ')' }, c[0] + '*'));
    });

    // like the old chart: dark labels on both axes for the bar under the
    // mouse, otherwise for the picked bar
    var lb = bars[hoverIndex !== null ? hoverIndex : picked];
    if (isFinite(lb.years)) svg.appendChild(pill(pad.left - 2, y(lb.years), lb.years + ' years', 'end'));
    svg.appendChild(pill(x(lb.rate), pad.top + plotH + 12, lb.rate + '%', 'middle'));

    box.replaceChildren(svg);

    var cur = bars[picked];
    box.setAttribute('aria-valuenow', cur.rate);
    box.setAttribute('aria-valuetext', cur.rate + '% savings rate, ' + (isFinite(cur.years) ? cur.years + ' years' : 'never'));
  }

  // a rounded dark label.  anchor is where cx is: 'middle' or 'end'
  function pill(cx, cy, text, anchor) {
    var w = text.length * 7 + 12;
    var left = anchor === 'end' ? cx - w : cx - w / 2;
    left = Math.max(0, left);
    var g = el('g', { class: 'pill' });
    g.appendChild(el('rect', { x: left, y: cy - 9, width: w, height: 18, rx: 4 }));
    g.appendChild(el('text', { x: left + w / 2, y: cy + 4, 'text-anchor': 'middle' }, text));
    return g;
  }

  function indexAt(clientX) {
    if (!geometry) return null;
    var rect = $('chart').getBoundingClientRect();
    var px = clientX - rect.left;
    var rate = ((px - geometry.pad.left) / geometry.plotW) * (100 + barStep) - barStep / 2;
    if (rate < -barStep / 2 || rate > 100 + barStep / 2) return null;
    return Math.max(0, Math.min(lastIndex(), Math.round(rate / barStep)));
  }

  function pickRate(rate) {
    edited = {};
    state.savingsRate = rate;
    recalculate.savingsRate();
    touched = true;
    clearWarnings();
    render();
  }

  function clearWarnings() {
    FIELDS.forEach(function (name) {
      $(name + 'Warning').textContent = '';
      $(name).setAttribute('aria-invalid', 'false');
    });
  }

  // === wiring ===

  function update() {
    if (syncFromInputs()) render();
  }

  // "Crunch the numbers": bring the answer into view (it's below the fold
  // on phones) and flash it, so the click visibly did something
  function showAnswer() {
    if (!syncFromInputs()) return;
    render();
    var answer = document.querySelector('.answer .big-numbers');
    var pop = function () {
      answer.classList.remove('flash');
      void answer.offsetWidth;  // restart the animation
      answer.classList.add('flash');
    };
    var box = answer.getBoundingClientRect();
    if (box.top >= 0 && box.bottom <= window.innerHeight) return pop();

    // scroll first, then pop once the answer has arrived.  browsers
    // without the scrollend event get a timer instead.
    var still = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    var done = false;
    var arrived = function () {
      if (done) return;
      done = true;
      window.removeEventListener('scrollend', arrived);
      pop();
    };
    window.addEventListener('scrollend', arrived);
    setTimeout(arrived, still ? 0 : 800);
    answer.scrollIntoView({ behavior: still ? 'auto' : 'smooth', block: 'center' });
  }

  function setupToggles() {
    var more = $('moreOptions');
    var toggle = $('toggleMore');
    var setOpen = function (open) {
      more.hidden = !open;
      toggle.textContent = open ? '- Show less options' : '+ Show more options';
      toggle.setAttribute('aria-expanded', String(open));
    };
    var remembered = false;
    try { remembered = window.localStorage.getItem('fi-more-options') === '1'; } catch (e) {}
    setOpen(remembered || state.annualPct !== DEFAULTS.annualPct || state.withdrawalRate !== DEFAULTS.withdrawalRate);
    toggle.addEventListener('click', function () {
      setOpen(more.hidden);
      try {
        if (!more.hidden) window.localStorage.setItem('fi-more-options', '1');
        else window.localStorage.removeItem('fi-more-options');
      } catch (e) {}
    });

    var btn = $('toggleAssumptions');
    btn.addEventListener('click', function () {
      var box = $('assumptions');
      box.hidden = !box.hidden;
      btn.textContent = box.hidden ? 'Show assumptions' : 'Hide assumptions';
      btn.setAttribute('aria-expanded', String(!box.hidden));
    });

    // per year or per month
    try { if (window.localStorage.getItem('fi-period') === 'monthly') period = 'monthly'; } catch (e) {}
    if (new URLSearchParams(window.location.search).get('period') === 'monthly') period = 'monthly';
    document.querySelectorAll('input[name=period]').forEach(function (radio) {
      radio.checked = radio.value === period;
      radio.addEventListener('change', function () {
        // keep anything typed in the old period.  bad input is thrown away.
        if (!syncFromInputs()) { edited = {}; clearWarnings(); }
        period = radio.value;
        try { window.localStorage.setItem('fi-period', period); } catch (e) {}
        render();
      });
    });

    // the full table is open on big screens, one tap away on phones
    $('breakdown').open = window.matchMedia('(min-width: 40em)').matches;
  }

  function setupShare() {
    $('share').addEventListener('click', function () {
      if (!syncFromInputs()) return;
      touched = true;
      render();
      var years = M.roundYears(M.yearsToFI(args(), state.savingsRate / 100));
      window.shareLink({
        title: 'When can I retire?',
        text: isFinite(years)
          ? 'With a ' + formatRate(state.savingsRate) + '% savings rate I can retire in ' + years + ' years.'
          : 'When can I retire?',
        url: window.location.origin + shareUrl(),
      }, $('copied'));
    });
  }

  function setupChart() {
    var chart = $('chart');
    if (window.matchMedia('(hover: none)').matches) $('chartVerb').textContent = 'Tap';
    chart.addEventListener('pointermove', function (e) {
      if (e.pointerType !== 'mouse') return;
      var i = indexAt(e.clientX);
      if (i !== hoverIndex) { hoverIndex = i; renderChart(); }
    });
    chart.addEventListener('pointerleave', function () {
      if (hoverIndex !== null) { hoverIndex = null; renderChart(); }
    });
    chart.addEventListener('click', function (e) {
      var i = indexAt(e.clientX);
      if (i !== null && i > 0) pickRate(i * barStep);
    });
    chart.addEventListener('keydown', function (e) {
      var i = pickedIndex();
      var next = e.key === 'ArrowLeft' || e.key === 'ArrowDown' ? i - 1
               : e.key === 'ArrowRight' || e.key === 'ArrowUp' ? i + 1
               : e.key === 'Home' ? 1 : e.key === 'End' ? lastIndex() : null;
      if (next === null) return;
      e.preventDefault();
      pickRate(Math.max(1, Math.min(lastIndex(), next)) * barStep);
    });

    var lastWidth = chart.clientWidth;
    var onResize = function () {
      if (chart.clientWidth !== lastWidth) { lastWidth = chart.clientWidth; renderChart(); }
    };
    if (window.ResizeObserver) new ResizeObserver(onResize).observe(chart);
    else window.addEventListener('resize', onResize);
  }

  function start() {
    touched = readUrl();
    var form = $('fiForm');
    FIELDS.forEach(function (name) {
      $(name).addEventListener('input', function () { edited[name] = true; });
      $(name).addEventListener('change', update);
    });
    form.addEventListener('submit', function (e) { e.preventDefault(); showAnswer(); });
    setupToggles();
    setupShare();
    setupChart();
    render();
  }

  start();
})();
