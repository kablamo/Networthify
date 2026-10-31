// Run with: node --test site-tests/
const test   = require('node:test');
const assert = require('node:assert');

const RealCostMath = require('../site/js/real-cost-math.js');

// Expected values copied from t/out/realCost.t (the old Perl implementation)
const defaults = {
  price: 10, period: 'monthly', roi: 7, withdrawalRate: 4,
  savingsRate: 100, hourlyWage: 20, workDay: 8, daysPerYear: 232,
};

test('matches the old Perl output', () => {
  const out = RealCostMath.realCost(defaults);

  assert.strictEqual(out.egg, '3,000');
  assert.strictEqual(out.equations,
    '$3,000 x 0.04       = $120.00 a year \n' +
    '$3,000 x 0.04 /  12 = $ 10.00 a month\n' +
    '$3,000 x 0.04 /  52 = $  2.31 a week \n' +
    '$3,000 x 0.04 / 365 = $  0.33 a day  \n');

  // the old site said "6hrs", "1dy  4hrs", "8dys 0hrs": the same numbers, in words now
  const expected = [
    ['124', '6 hours'], ['257', '1 day 4 hours'], ['399', '2 days 3 hours'],
    ['552', '3 days 3 hours'], ['716', '4 days 3 hours'], ['892', '5 days 4 hours'],
    ['1,080', '6 days 5 hours'], ['1,282', '8 days'], ['1,499', '9 days 2 hours'],
    ['1,731', '10 days 6 hours'], ['1,980', '12 days 2 hours'], ['2,247', '14 days'],
    ['2,533', '15 days 6 hours'], ['2,840', '17 days 6 hours'], ['3,170', '19 days 6 hours'],
    ['3,523', '22 days'], ['3,901', '24 days 3 hours'], ['4,307', '26 days 7 hours'],
    ['4,743', '29 days 5 hours'], ['5,209', '32 days 4 hours'],
  ];
  assert.deepStrictEqual(out.costs.slice(0, 20).map(c => [c.money, c.timeWorked]), expected);
  assert.strictEqual(out.costs.length, 30);
});

test('matches the live site work time for the defaults', () => {
  // networthify.com/calculator/recurring-charges shows "18dys 6hrs"
  assert.strictEqual(RealCostMath.realCost(defaults).workTime, '18 days 6 hours');
});

test('short durations for the headline', () => {
  assert.strictEqual(RealCostMath.realCost(defaults).workTimeShort, '19 days');
  assert.strictEqual(RealCostMath.realCost(defaults).costs[9].timeWorkedShort, '11 days');
  assert.strictEqual(RealCostMath.shortDuration(6.4, 8, 232), '6 hours');
  assert.strictEqual(RealCostMath.shortDuration(0.2, 8, 232), '1 hour');
  assert.strictEqual(RealCostMath.shortDuration(8 * 232 + 8 * 45 + 2, 8, 232), '1.2 years');
  assert.strictEqual(RealCostMath.shortDuration(8 * 232, 8, 232), '1 year');
});

test('durations longer than a year', () => {
  // the old site said "1yr  045dys 2hrs"
  assert.strictEqual(RealCostMath.humanDuration(8 * 232 + 8 * 45 + 2, 8, 232), '1 year 45 days');
  assert.strictEqual(RealCostMath.humanDuration(8 * 232 * 3, 8, 232), '3 years');
  assert.strictEqual(RealCostMath.humanDuration(1, 8, 232), '1 hour');
});

test('counts all of your pay when no savings rate is given', () => {
  const { savingsRate, ...rest } = defaults;
  assert.strictEqual(RealCostMath.realCost(rest).workTime, '18 days 6 hours');
});

test('paid and cost for the chart', () => {
  assert.strictEqual(Math.round(RealCostMath.paidAfter(defaults, 10)), 1200);
  assert.strictEqual(RealCostMath.formatNumber(RealCostMath.costAfter(defaults, 10)), '1,731');
  assert.strictEqual(RealCostMath.costAfter({ ...defaults, roi: 0 }, 2.5), 300);
});

test('other periods', () => {
  assert.strictEqual(RealCostMath.realCost({ ...defaults, period: 'annual', price: 120 }).egg, '3,000');
  assert.strictEqual(RealCostMath.realCost({ ...defaults, period: 'daily', price: 1 }).egg, '9,125');
});
