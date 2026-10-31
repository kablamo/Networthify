// "Do I need a high income to retire early?"  Two people save the same share
// of different incomes.  Uses the calculator's math in fi-math.js.
(function () {
  'use strict';

  var M = window.FIMath;
  var $ = function (id) { return document.getElementById(id); };

  // the calculator's defaults
  var RETURN = 5;
  var WITHDRAWAL = 4;

  function money(n) { return '$' + M.toMoney(n); }

  var shortMoney = window.LineChart.shortMoney;

  function years(y) { return M.roundYears(y) + ' years'; }

  // net worth after t years, saving once at the end of each year like the
  // calculator, but smooth between years so the lines aren't steps
  function networth(savings, t) {
    var r = RETURN / 100;
    return savings * (Math.pow(1 + r, t) - 1) / r;
  }

  function read(id) {
    var v = M.cleanNumber($(id).value);
    return isFinite(v) ? v : NaN;
  }

  function render() {
    var rate = read('rate');
    var incomes = [read('aIncome'), read('bIncome')];
    var warning = $('pairWarning');
    var bad = !(rate > 0 && rate < 100) ? 'Pick a savings rate between 1% and 99%.'
            : !(incomes[0] > 0 && incomes[1] > 0) ? 'Enter two incomes above zero.' : '';
    warning.hidden = !bad;
    warning.textContent = bad;
    if (bad) return;

    $('rateOut').textContent = rate + '%';
    $('rate').setAttribute('aria-valuetext', rate + '% of their pay');
    $('rate').style.setProperty('--fill', (rate - $('rate').min) / ($('rate').max - $('rate').min));
    var s = rate / 100;
    var people = incomes.map(function (income, i) {
      var savings = s * income;
      var spending = income - savings;
      return { name: i ? 'Waffles' : 'Pickles', income: income, savings: savings,
               spending: spending, goal: spending / (WITHDRAWAL / 100) };
    });
    var t = M.yearsToFI({ income: incomes[0], initialBalance: 0, annualPct: RETURN, withdrawalRate: WITHDRAWAL }, s);

    ['a', 'b'].forEach(function (k, i) {
      var p = people[i];
      $(k + 'Saves').textContent = money(p.savings);
      $(k + 'Spends').textContent = money(p.spending);
      $(k + 'Goal').textContent = money(p.goal);
      $(k + 'Years').textContent = years(t);
    });
    $('bothYears').textContent = years(t);
    $('aEarns').textContent = money(incomes[0]);
    $('bEarns').textContent = money(incomes[1]);

    var rich = people[0].income > people[1].income ? people[0] : people[1];
    var poor = rich === people[0] ? people[1] : people[0];
    var times = Math.round(rich.income / poor.income * 10) / 10;
    $('pairWhy').textContent = times === 1
      ? 'Same pay, same savings, same date.'
      : rich.name + ' saves ' + times + ' times as much as ' + poor.name + ', but needs ' + times + ' times as much too.';

    // the x axis stays put as the rate changes: it fits the slowest rate on the slider
    var slowest = M.yearsToFI({ income: 1, initialBalance: 0, annualPct: RETURN, withdrawalRate: WITHDRAWAL }, $('rate').min / 100);
    var xMax = Math.ceil(slowest / 5) * 5;
    window.LineChart.draw($('dollarsChart'), {
      xMax: xMax, yMax: rich.goal, retire: t, retireText: M.roundYears(t) + ' yrs',
      yFormat: shortMoney, xTitle: 'Years of saving',
      goals: people.map(function (p) { return { value: p.goal, label: p.name + ' needs ' + shortMoney(p.goal) }; }),
      lines: people.map(function (p, i) {
        return { cls: i ? 'high' : 'low', values: function (x) { return networth(p.savings, x); } };
      }),
      label: 'Net worth in dollars.  Pickles reaches ' + money(people[0].goal) +
        ' and Waffles reaches ' + money(people[1].goal) + ', both in ' + years(t) + '.',
    });
  }

  ['rate', 'aIncome', 'bIncome'].forEach(function (id) { $(id).addEventListener('input', render); });

  // a shadow on the slider bar once it's stuck to the top
  if ('IntersectionObserver' in window) {
    new IntersectionObserver(function (entries) {
      $('rateBar').classList.toggle('stuck', !entries[0].isIntersecting && entries[0].boundingClientRect.top < 0);
    }).observe($('stickMark'));
  }

  // the labels under the slider jump to that rate, and sit where it would put the thumb
  var slider = $('rate');
  var lo = +slider.min, hi = +slider.max;
  Array.prototype.forEach.call(document.querySelectorAll('.rate-ticks button'), function (b) {
    var f = (b.getAttribute('data-rate') - lo) / (hi - lo);
    b.style.left = 'calc(var(--thumb) / 2 + (100% - var(--thumb)) * ' + f + ')';
    b.addEventListener('click', function () {
      slider.value = b.getAttribute('data-rate');
      render();
    });
  });
  var width = window.innerWidth;
  window.addEventListener('resize', function () {
    if (window.innerWidth === width) return;
    width = window.innerWidth;
    render();
  });
  render();
})();
