// Recurring charges math.  A port of Networth::Out::RealCost and
// Networth::Roles::HumanDuration.  No DOM code so it can be tested in node.
(function (root) {
  'use strict';

  // 1234.5 -> "1,235".  Like Number::Format::format_number($n, $decimals, 1).
  function formatNumber(n, decimals) {
    decimals = decimals || 0;
    return n.toLocaleString('en-US', {
      minimumFractionDigits: decimals,
      maximumFractionDigits: decimals,
    });
  }

  function plural(n, word) { return n + ' ' + word + (n === 1 ? '' : 's'); }

  // Turn a number of working hours into "18 days 6 hours" or "1 year 45 days"
  // given the length of a working day and the number of working days in a
  // year.  Same arithmetic as the old site's "18dys 6hrs".  Parts that are
  // zero are left out, and hours are dropped once it's more than a year.
  function humanDuration(hours, workDay, daysPerYear) {
    if (hours < workDay) return plural(Number(formatNumber(hours)), 'hour');

    var dys = Math.trunc(hours / workDay);
    var hrs = Math.trunc(hours) % Math.trunc(workDay);
    if (dys < daysPerYear) return plural(dys, 'day') + (hrs ? ' ' + plural(hrs, 'hour') : '');

    var yrs = Math.trunc(dys / daysPerYear);
    dys = dys % Math.trunc(daysPerYear);
    return plural(yrs, 'year') + (dys ? ' ' + plural(dys, 'day') : '');
  }

  // A rounder version for big headline numbers: "19 days" rather than
  // "18 days 6 hours", "2.6 years" rather than "2 years 144 days".  Hours
  // only when it's under a day.
  function shortDuration(hours, workDay, daysPerYear) {
    if (hours < workDay) return plural(Math.max(1, Math.round(hours)), 'hour');
    var dys = Math.round(hours / workDay);
    if (dys < daysPerYear) return plural(dys, 'day');
    var yrs = Math.round(hours / workDay / daysPerYear * 10) / 10;
    return yrs + (yrs === 1 ? ' year' : ' years');
  }

  // the charge as a monthly amount
  function monthlyPrice(args) {
    var price = args.price;
    return args.period === 'annual' ? price / 12
         : args.period === 'weekly' ? price * 52 / 12
         : args.period === 'daily'  ? price * 365 / 12
         : price;
  }

  // what you've paid after this many years (may be fractional)
  function paidAfter(args, years) { return monthlyPrice(args) * years * 12; }

  // what it has cost after this many years, counting the investment returns
  // you gave up by paying it each month instead of investing
  function costAfter(args, years) {
    var roi = args.roi / 100 / 12;
    var price = monthlyPrice(args);
    return roi === 0 ? price * years * 12 : price * (Math.pow(1 + roi, years * 12) - 1) / roi;
  }

  function realCost(args) {
    // the share of pay that goes to this.  The page always counts all of it.
    var savingsRate = (args.savingsRate === undefined ? 100 : args.savingsRate) / 100;
    var w           = args.withdrawalRate / 100;
    var wage        = args.hourlyWage;
    var price       = monthlyPrice(args);

    var duration = function (h) {
      return humanDuration(h, args.workDay, args.daysPerYear);
    };

    // what the charge costs you including the investment returns you gave up
    var costs = [];
    for (var years = 1; years <= 30; years++) {
      var money = costAfter(args, years);
      costs.push({
        years:      years,
        money:      formatNumber(money),
        value:      money,
        timeWorked: duration(money / (wage * savingsRate)),
        timeWorkedShort: shortDuration(money / (wage * savingsRate), args.workDay, args.daysPerYear),
      });
    }

    // the nest egg you need to pay for the charge forever
    var egg = price / (w / 12);

    var annualCost  = formatNumber(egg * w, 2);
    var monthlyCost = formatNumber(egg * (w / 12), 2);
    var weeklyCost  = formatNumber(egg * (w / 52), 2);
    var dailyCost   = formatNumber(egg * (w / 365), 2);
    var pad = function (s) { return ' '.repeat(annualCost.length - s.length) + s; };

    var left = '$' + formatNumber(egg) + ' x ' + w;
    var equations =
      left + '       = $' + annualCost       + ' a year \n' +
      left + ' /  12 = $' + pad(monthlyCost) + ' a month\n' +
      left + ' /  52 = $' + pad(weeklyCost)  + ' a week \n' +
      left + ' / 365 = $' + pad(dailyCost)   + ' a day  \n';

    return {
      costs:     costs,
      egg:       formatNumber(egg),
      workTime:  duration(egg / (wage * savingsRate)),
      workTimeShort: shortDuration(egg / (wage * savingsRate), args.workDay, args.daysPerYear),
      equations: equations,
    };
  }

  var RealCostMath = {
    realCost:      realCost,
    humanDuration: humanDuration,
    paidAfter:     paidAfter,
    costAfter:     costAfter,
    shortDuration: shortDuration,
    formatNumber:  formatNumber,
  };

  if (typeof module !== 'undefined' && module.exports) module.exports = RealCostMath;
  else root.RealCostMath = RealCostMath;
})(this);
