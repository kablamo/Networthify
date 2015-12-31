FI.Math = function (args) {
  var that = this;
  var undefined;

  this.initialBalance = args.initialBalance;
  this.income         = args.income;
  this.annualPct      = args.annualPct;
  this.withdrawalRate = args.withdrawalRate;

  var whenComplex = function (savingsRate) {
    var annualPct      = that.annualPct / 100;
    var withdrawalRate = that.withdrawalRate / 100;
    var numerator   = Math.log((((annualPct * (1 - savingsRate) * that.income) / withdrawalRate) + (savingsRate * that.income)) / ((annualPct * that.initialBalance) + (savingsRate * that.income)));
    var denominator = Math.log(1 + annualPct);
    var years       = numerator / denominator;
    return years;
  };

  var whenSimple = function (savingsRate) {
    var annualPct      = that.annualPct / 100;
    var withdrawalRate = that.withdrawalRate / 100;
    var numerator   = Math.log((1 - savingsRate) * (1 / withdrawalRate ) * (annualPct / savingsRate) + 1);
    var denominator = Math.log(1 + annualPct);
    var years       = numerator / denominator;
    return years;
  };

  this.when = function (savingsRate) {
    if (that.income && (that.income !== 0 || that.initialBalance !== 0)) {
      return whenComplex(savingsRate);
    }
    else {
      return whenSimple(savingsRate);
    }
  };

  return this;
};
