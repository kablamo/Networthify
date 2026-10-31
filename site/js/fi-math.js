// Early retirement math.  No DOM code in here so it can be tested in node.
//
// Assumes you save once at the end of each year and that annualPct is the
// real (after tax and inflation) return.  You are financially independent
// when your portfolio is big enough that withdrawalRate% of it covers your
// annual expenses.
(function (root) {
  'use strict';

  // Years until financially independent at the given savings rate (0-1).
  // Returns Infinity if you never get there.
  function yearsToFI(args, savingsRate) {
    var income         = args.income;
    var initialBalance = args.initialBalance;
    var r              = args.annualPct / 100;
    var w              = args.withdrawalRate / 100;
    var savings        = savingsRate * income;
    var expenses       = (1 - savingsRate) * income;

    if (initialBalance * w >= expenses) return 0;
    if (r === 0) return savings > 0 ? (expenses / w - initialBalance) / savings : Infinity;

    // Solve initialBalance*(1+r)^n + savings*((1+r)^n - 1)/r = expenses/w
    var top    = (r * expenses / w) + savings;
    var bottom = (r * initialBalance) + savings;
    var years  = Math.log(top / bottom) / Math.log(1 + r);

    return isFinite(years) && years >= 0 ? years : Infinity;
  }

  // Round to one decimal place the way the headline displays it.
  function roundYears(years) {
    return isFinite(years) ? Math.round(years * 10) / 10 : Infinity;
  }

  // Year by year growth of the portfolio, ending with the year you reach FI.
  // Uses the same end of year convention as yearsToFI() so they agree.
  function yearByYear(args, annualSavings, annualExpenses, years) {
    var r      = args.annualPct / 100;
    var w      = args.withdrawalRate / 100;
    var target = annualExpenses / w;
    var rows   = [];
    var networth = args.initialBalance;

    if (!isFinite(years)) return rows;

    for (var year = 1; year <= Math.max(1, Math.ceil(years)); year++) {
      var rturn = networth * r;
      networth += rturn + annualSavings;
      rows.push({
        year:     year,
        income:   args.income,
        expenses: annualExpenses,
        rturn:    rturn,
        change:   rturn + annualSavings,
        networth: networth,
        // how much of your expenses a withdrawalRate% withdrawal would cover
        covered:  annualExpenses > 0 ? (networth * w) / annualExpenses : 1,
        fi:       networth >= target - 0.005,
      });
    }

    return rows;
  }

  // Strip everything that isn't part of a number: "$50,000" -> "50000"
  function cleanNumber(str) {
    var v = String(str === undefined || str === null ? '' : str).trim();
    v = v.replace(/^\./, '0.');
    v = v.replace(/^[^0-9\-.]*/, '');
    v = v.replace(/[^0-9.]*$/, '');
    v = v.replace(/,/g, '');
    return v === '' || isNaN(v) ? NaN : Number(v);
  }

  function toMoney(n) {
    return Math.round(n).toLocaleString('en-US');
  }

  var FIMath = {
    yearsToFI:   yearsToFI,
    roundYears:  roundYears,
    yearByYear:  yearByYear,
    cleanNumber: cleanNumber,
    toMoney:     toMoney,
  };

  if (typeof module !== 'undefined' && module.exports) module.exports = FIMath;
  else root.FIMath = FIMath;
})(this);
