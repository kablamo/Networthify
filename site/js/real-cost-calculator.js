// The recurring charges calculator page.
(function () {
  'use strict';

  var M = window.RealCostMath;
  var $ = function (id) { return document.getElementById(id); };

  var DEFAULTS = {
    price: 10, period: 'monthly', hourlyWage: 20, roi: 7,
    withdrawalRate: 4, workDay: 8, daysPerYear: 232, years: 10,
  };
  var NUMBERS = ['price', 'hourlyWage', 'years', 'roi', 'withdrawalRate', 'workDay', 'daysPerYear'];
  var PERIODS = ['daily', 'weekly', 'monthly', 'annual'];
  var EVERY = { daily: 'a day', weekly: 'a week', monthly: 'a month', annual: 'a year' };
  var UNIT  = { daily: '/day', weekly: '/wk', monthly: '/mo', annual: '/yr' };
  var PER_YEAR = { daily: 365, weekly: 52, monthly: 12, annual: 1 };
  // the most years the page counts: the chart and the longest tile
  var MAX_YEARS = 30;
  // the years shown in the "over time" table, as well as the one picked
  var YEARS = [1, 5, 10, 15, 20, 25, 30];

  // 10 -> "$10", 9.5 -> "$9.50"
  function money(n) { return '$' + M.formatNumber(n, n % 1 ? 2 : 0); }

  function clean(str) {
    var v = String(str === null || str === undefined ? '' : str).replace(/[$,%\s]/g, '');
    return v === '' || isNaN(v) ? NaN : Number(v);
  }

  function getPeriod() { return document.querySelector('input[name=period]:checked').value; }
  function setPeriod(p) { document.querySelector('input[name=period][value=' + p + ']').checked = true; }

  function readUrl() {
    var params = new URLSearchParams(window.location.search);
    NUMBERS.forEach(function (name) {
      var v = clean(params.get(name));
      $(name).value = v ? v : DEFAULTS[name];
    });
    var period = params.get('period');
    setPeriod(PERIODS.indexOf(period) >= 0 ? period : DEFAULTS.period);
    return params.toString() !== '';
  }

  function readForm() {
    var values = { period: getPeriod() };
    var ok = true;
    NUMBERS.forEach(function (name) {
      var v = clean($(name).value);
      var error = isNaN(v) ? 'required' : (v <= 0 && name !== 'roi') ? 'must be more than 0' : '';
      if (name === 'years' && !error && (v !== Math.round(v) || v > MAX_YEARS)) error = 'a whole number up to ' + MAX_YEARS;
      $(name + 'Warning').textContent = error;
      $(name).setAttribute('aria-invalid', error ? 'true' : 'false');
      if (error) ok = false;
      values[name] = v;
    });
    return ok ? values : null;
  }

  function shareUrl(values) {
    return '/calculator/recurring-charges?' + new URLSearchParams(values).toString();
  }

  function render(values, updateUrl) {
    var out = M.realCost(values);

    var ten = out.costs[values.years - 1];
    $('yearsText').textContent          = values.years + (values.years === 1 ? ' year' : ' years');
    var charge = money(values.price) + ' ' + EVERY[values.period];
    $('priceUnit').textContent          = UNIT[values.period];
    $('chargeText').textContent         = charge;
    $('chargeText2').textContent        = charge;
    $('tenYearText').textContent        = '$' + ten.money;
    var paid = M.paidAfter(values, values.years);
    $('paidText').textContent           = '$' + M.formatNumber(paid);
    $('lostText').textContent           = '$' + M.formatNumber(ten.value - paid);
    $('tenYearWork').textContent        = ten.timeWorkedShort;
    $('eggText').textContent            = '$' + out.egg;
    $('eggText2').textContent           = '$' + out.egg;
    $('workTimeText').textContent       = out.workTimeShort;
    $('annualText').textContent         = money(values.price * PER_YEAR[values.period]);
    $('annualText2').textContent        = money(values.price * PER_YEAR[values.period]);
    $('withdrawalRateText2').textContent = values.withdrawalRate;
    $('wageText2').textContent          = money(values.hourlyWage);
    $('wageText3').textContent          = money(values.hourlyWage);
    $('workDayText').textContent        = values.workDay;
    $('withdrawalRateText').textContent = values.withdrawalRate;
    $('roiText').textContent            = values.roi;

    // drawn as a bar chart like the savings rate tables: gray bars, with
    // the picked number of years in green
    var shown = out.costs.filter(function (c) { return YEARS.indexOf(c.years) >= 0 || c.years === values.years; });
    var most = shown[shown.length - 1].value;
    $('costTable').innerHTML =
      '<thead><tr><th>Years</th><th>Real cost</th><th><span>Work needed</span> <span>to earn it</span></th></tr></thead><tbody>' +
      shown.map(function (c) {
        return '<tr' + (c.years === values.years ? ' class="you"' : '') + '><td>' + c.years + '</td>' +
               '<td><span class="rate"><span class="track"><span class="bar" style="left:0;width:' +
               Math.max(1, c.value / most * 100).toFixed(1) + '%"></span></span>' +
               '<span class="v">$' + c.money + '</span></span></td>' +
               '<td class="work">' + c.timeWorkedShort + '</td></tr>';
      }).join('') + '</tbody>';

    drawGap(values);

    if (updateUrl) {
      try { window.history.replaceState(null, '', shareUrl(values)); } catch (e) {}
    }
  }

  // the fees against what it really costs, with the missed returns between
  function drawGap(values) {
    var years = MAX_YEARS;
    var paid = function (t) { return M.paidAfter(values, t); };
    var cost = function (t) { return M.costAfter(values, t); };
    var paidText = money(Math.round(paid(years)));
    var costText = '$' + M.formatNumber(cost(years));
    window.LineChart.draw($('gapChart'), {
      xMax: years, yMax: cost(years), yFormat: window.LineChart.shortMoney, xTitle: 'Years',
      gap: { upper: cost, lower: paid, label: cost(years) > paid(years) * 1.15 ? 'missed returns' : '' },
      lines: [{ cls: 'low', values: paid }, { cls: 'cost', values: cost }],
      ends: [{ value: cost(years), label: costText }, { value: paid(years), label: paidText, below: true }],
      hoverFrom: 1,
      picked: values.years,
      // clicking a year makes it the one the answer counts, like picking a
      // savings rate on the early retirement calculator's chart
      onPick: function (t) {
        $('years').value = t;
        var v = readForm();
        if (v) render(v, true);
      },
      hover: function (t) {
        return {
          title: t === 1 ? '1 year' : t + ' years',
          // the same three numbers as the answer above the chart
          points: [
            { value: cost(t), text: '$' + M.formatNumber(cost(t)) + ' real cost', cls: 'cost' },
            { value: (cost(t) + paid(t)) / 2, text: '$' + M.formatNumber(cost(t) - paid(t)) + ' missed returns', dot: false },
            { value: paid(t), text: '$' + M.formatNumber(paid(t)) + ' fees', cls: 'low' },
          ],
        };
      },
      label: 'Over ' + years + ' years you pay ' + paidText + ' in subscription fees, but counting the investment returns you miss, it costs ' + costText + '.',
    });
  }

  function setupMoreOptions() {
    var more = $('moreOptions');
    var toggle = $('toggleMore');
    var setOpen = function (open) {
      more.hidden = !open;
      toggle.textContent = open ? '- Fewer options' : '+ More options';
      toggle.setAttribute('aria-expanded', String(open));
    };
    var remembered = false;
    try { remembered = window.localStorage.getItem('recurring-charges-more-options') === '1'; } catch (e) {}
    setOpen(remembered);
    toggle.addEventListener('click', function () {
      setOpen(more.hidden);
      try {
        if (!more.hidden) window.localStorage.setItem('recurring-charges-more-options', '1');
        else window.localStorage.removeItem('recurring-charges-more-options');
      } catch (e) {}
    });
  }

  function setupShare() {
    $('share').addEventListener('click', function () {
      var values = readForm();
      if (!values) return;
      var out = M.realCost(values);
      render(values, true);
      window.shareLink({
        title: 'What do my subscriptions really cost?',
        text: 'A ' + values.period + ' charge of $' + values.price + ' really costs $' + out.costs[values.years - 1].money + ' over ' + values.years + (values.years === 1 ? ' year.' : ' years.'),
        url: window.location.origin + shareUrl(values),
      }, $('copied'));
    });
  }

  // "Crunch the numbers": bring the answer into view, then make it pop,
  // like the early retirement calculator
  function showAnswer() {
    var answer = $('costNumbers');
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

  function start() {
    var fromUrl = readUrl();
    var update = function (e) {
      if (e) e.preventDefault();
      var values = readForm();
      if (values) render(values, true);
    };
    $('costForm').addEventListener('submit', function (e) {
      e.preventDefault();
      var values = readForm();
      if (!values) return;
      render(values, true);
      showAnswer();
    });
    NUMBERS.forEach(function (name) { $(name).addEventListener('change', function () { update(); }); });
    Array.prototype.forEach.call(document.querySelectorAll('input[name=period]'), function (r) {
      r.addEventListener('change', function () { update(); });
    });
    setupMoreOptions();
    if (window.matchMedia('(hover: none)').matches) $('gapVerb').textContent = 'Tap';
    // the chart is drawn to fit its box, so redraw when the width changes
    var width = window.innerWidth;
    window.addEventListener('resize', function () {
      if (window.innerWidth === width) return;
      width = window.innerWidth;
      var values = readForm();
      if (values) drawGap(values);
    });
    setupShare();
    render(readForm() || DEFAULTS, false);
    if (fromUrl) update();
  }

  start();
})();
