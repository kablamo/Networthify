// Run with: node --test site-tests/
const test   = require('node:test');
const assert = require('node:assert');
const fs     = require('node:fs');
const path   = require('node:path');
const vm     = require('node:vm');

const FIMath = require('../site/js/fi-math.js');

// The math from the old site, so we can prove the headline numbers didn't change
function oldWhen(args, savingsRate) {
  const src = fs.readFileSync(path.join(__dirname, '../root/js/fi.math.js'), 'utf8');
  const ctx = { FI: {}, Math };
  vm.runInNewContext(src, ctx);
  return ctx.FI.Math.call({}, args).when(savingsRate);
}

const base = { income: 50000, initialBalance: 0, annualPct: 5, withdrawalRate: 4 };

test('defaults: 60% savings rate retires in 12.4 years', () => {
  assert.strictEqual(FIMath.roundYears(FIMath.yearsToFI(base, 0.6)), 12.4);
});

test('50% savings rate matches the well known 16.6 years', () => {
  assert.strictEqual(FIMath.roundYears(FIMath.yearsToFI(base, 0.5)), 16.6);
});

test('headline numbers match the old site for every chart bar', () => {
  const scenarios = [
    base,
    { income: 70000,  initialBalance: 0,     annualPct: 5, withdrawalRate: 4 },
    { income: 32000,  initialBalance: 40000, annualPct: 5, withdrawalRate: 4 },
    { income: 120000, initialBalance: 250000, annualPct: 7, withdrawalRate: 3.5 },
    { income: 3000000, initialBalance: 0,    annualPct: 7, withdrawalRate: 4 },
  ];
  for (const args of scenarios) {
    for (let i = 2; i <= 100; i += 2) {
      const old = oldWhen(args, i / 100);
      if (!(old > 0)) continue; // the old site went negative once you were already FI
      assert.strictEqual(
        FIMath.roundYears(FIMath.yearsToFI(args, i / 100)),
        Math.round(old * 10) / 10,
        `income ${args.income} rate ${i}%`
      );
    }
  }
});

test('never retire with 0% savings and no portfolio', () => {
  assert.strictEqual(FIMath.yearsToFI(base, 0), Infinity);
});

test('never retire when spending more than you earn', () => {
  assert.strictEqual(FIMath.yearsToFI(base, -0.2), Infinity);
});

test('already FI when the portfolio covers expenses', () => {
  const args = { ...base, initialBalance: 600000 };
  assert.strictEqual(FIMath.yearsToFI(args, 0.6), 0);
});

test('year by year table reaches FI in the same year as the headline', () => {
  const years = FIMath.yearsToFI(base, 0.6);
  const rows  = FIMath.yearByYear(base, 30000, 20000, years);
  assert.strictEqual(rows.length, 13);
  assert.strictEqual(rows.findIndex(r => r.fi) + 1, 13);
  assert.ok(rows[11].networth < 500000);
  assert.ok(rows[12].networth >= 500000);
  assert.strictEqual(Math.round(rows[0].networth), 30000);
});

test('table FI year always equals ceil(headline years)', () => {
  for (let i = 4; i <= 98; i += 2) {
    const s = i / 100;
    const years = FIMath.yearsToFI(base, s);
    const rows  = FIMath.yearByYear(base, s * 50000, (1 - s) * 50000, years);
    assert.strictEqual(rows.findIndex(r => r.fi) + 1, Math.ceil(years), `rate ${i}%`);
  }
});

test('cleanNumber', () => {
  assert.strictEqual(FIMath.cleanNumber('$50,000'), 50000);
  assert.strictEqual(FIMath.cleanNumber('.5'), 0.5);
  assert.strictEqual(FIMath.cleanNumber('60%'), 60);
  assert.strictEqual(FIMath.cleanNumber('-200'), -200);
  assert.ok(isNaN(FIMath.cleanNumber('')));
  assert.ok(isNaN(FIMath.cleanNumber('abc')));
});

test('0% return still works', () => {
  const args = { ...base, annualPct: 0 };
  assert.strictEqual(FIMath.yearsToFI(args, 0.6), 500000 / 30000);
});

test('the homepage is an exact copy of the calculator page', () => {
  const read = f => fs.readFileSync(path.join(__dirname, '../site', f), 'utf8');
  assert.strictEqual(read('index.html'), read('calculator/earlyretirement.html'),
    'run: cp site/calculator/earlyretirement.html site/index.html');
});
