FI.Plot = function (args) {
  var that = this;
  var undefined;

  this.math  = FI.Math(args);
  this.table = FI.Table();

  this.initialBalance = this.math.initialBalance;
  this.income         = this.math.income;
  this.annualPct      = this.math.annualPct;
  this.withdrawalRate = this.math.withdrawalRate;

  this.index           = 30;
  this.savingsRate     = 60;
  this.yearsToFI       = 12.4;
  this.annualExpenses  = args.expenses;
  this.annualSavings   = Math.round(100 * (this.income - this.annualExpenses))/100;
  this.monthlyExpenses = Math.round(this.annualExpenses / 12);
  this.monthlySavings  = Math.round(this.annualSavings / 12);

  this.data = [{
//  color     : '#028800',
//  color     : 'rgb(173, 255, 47)',
    color     : '#999',
    bars      : {
      show      : true,
      fill      : true,
      fillColor : '#ddd',
      lineWidth : 1,
      barWidth  : 2,
      align     : 'center',
    }
  }];

  this.generateGraphData = function () {
    that.data[0].data = [];
    that.data[0].yearsToFI = [];
    that.data[0].savingsRate = [];

    for (var i = 0; i <= 100; i = i + 2) {
        that.data[0].data.push([i,that.math.when(i/100)]);
        that.data[0].yearsToFI.push(Math.round(that.math.when(i/100) * 10) / 10);
        that.data[0].savingsRate.push(i);
    }

    return that.data;
  };

  this.plotOptions = {
    points     : {show: false, radius: 3},
    xaxis      : {color: '#333'},
    yaxis      : {ticks: 8, color: '#333'},
    shadowSize : 0,
    grid       : {
     hoverable         : true,
     clickable         : true,
     borderWidth       : 1,
     borderColor       : '#999',
     mouseActiveRadius : 50,
     backgroundColor   : '#fff', /* required for ie8 */
     color             : '#000', /* required for ie8 */
     autoHighlight     : true
    },
    hooks      : {
      draw : function (p, canvas) {
        var series = p.getData()[0];
        var axisx = series.xaxis, axisy = series.yaxis;

        var offset = p.getPlotOffset();
        canvas.save();
        canvas.translate(offset.left, offset.top);

        var ps = series.datapoints.pointsize;
        var pt = series.datapoints.points.slice(that.index * ps, (that.index + 1) * ps);
        var x  = pt[0];
        var y  = pt[1];

        var left   = axisx.p2c(x - 1);
        var right  = axisx.p2c(x + 1);
        var top    = axisy.p2c(y);
        var bottom = axisy.p2c(0);

        // fill
        canvas.beginPath();
        canvas.moveTo(left, bottom);
        canvas.lineTo(left, top);
        canvas.lineTo(right, top);
        canvas.lineTo(right, bottom);
        canvas.fillStyle = $.color.parse("#999").toString();
        canvas.fillStyle = $.color.parse("orange").toString();
        canvas.fillStyle = $.color.parse("rgb(173, 255, 47)").toString();
        canvas.fill();

        // outline
        canvas.lineWidth   = 1;
        canvas.strokeStyle = $.color.parse("#ff1f28").toString();
        canvas.strokeStyle = $.color.parse("#028800").toString();
        canvas.strokeStyle = $.color.parse("#666").toString();
        canvas.strokeStyle = $.color.parse("#999").toString();
        canvas.beginPath();
        canvas.moveTo(left, bottom);  // start
        canvas.lineTo(left, top);     // left
        canvas.lineTo(right, top);    // top
        canvas.lineTo(right, bottom); // right
        canvas.moveTo(left, bottom);  // bottom
        canvas.stroke();              // draw
      },
    }
  };

  this.redrawGraph = function() {
    var data             = that.generateGraphData();
    that.index           = Math.round(that.savingsRate / 2);
    that.yearsToFI       = Math.round(that.math.when(that.savingsRate/100) * 10) / 10;
    that.monthlyExpenses = Math.round(that.annualExpenses / 12);
    that.monthlySavings  = Math.round(that.annualSavings  / 12);
    that.plot            = $.plot($("#placeholder"), data, that.plotOptions);
    that.displayAllValues();
    that.table.redraw();
    that.resizeHandler();
  };

  this.handlePlotClick = function (event, pos, item) {
    if (pos.x < 2 || pos.x > 100) {
        return;
    }

    var series = that.plot.getData()[0];

    that.index           = Math.round(pos.x / 2);
    that.savingsRate     = series.savingsRate[that.index];
    that.yearsToFI       = series.yearsToFI[that.index];
    that.annualExpenses  = Math.round(that.income * (1 - (that.savingsRate / 100)));
    that.annualSavings   = that.income - that.annualExpenses;
    that.monthlyExpenses = Math.round(that.annualExpenses / 12);
    that.monthlySavings  = Math.round(that.annualSavings  / 12);
    that.plot            = $.plot($("#placeholder"), that.data, that.plotOptions);
    that.placeLabels(pos);

    that.displayAllValues();
    that.table.redraw();
    that.resizeHandler();
  };

  this.handlePlotHover = function (event, pos, item) {
    if (pos.x < 1 || pos.x > 100) {
        return;
    }

    var series = that.plot.getData()[0];
    var i = Math.round(pos.x / 2);

    that.placeLabels(pos);

    for (var j = 0; j < series.data.length; j++) {
        that.plot.unhighlight(series, j);
    }
    that.plot.highlight(series, i);
  };

  this.placeLabels = function(pos) {
    $('#savingsRateNew').remove();
    $('#yearsToFINew').remove();

    $('#placeholder').append(
      '<span id="savingsRateNew"></span><span id="yearsToFINew"></span>'
    );

    var series = that.plot.getData()[0];
    var i = Math.round(pos.x / 2);
    var x = Math.round(pos.x / 2) * 2;
    var xlabel = that.plot.pointOffset({x: x, y: that.plot.getAxes().yaxis.min});
    var ylabel = that.plot.pointOffset({x: that.plot.getAxes().xaxis.min, y: series.yearsToFI[i]});

    $('#savingsRateNew').css('position', 'absolute');
    $('#savingsRateNew').css('top', xlabel.top + 6);
    $('#savingsRateNew').css('left', xlabel.left - 15);
    $('#savingsRateNew').html(series.savingsRate[i] + '%');

    $('#yearsToFINew').css('position', 'absolute');
    $('#yearsToFINew').css('top', ylabel.top - 7);
    $('#yearsToFINew').css('left', ylabel.left - 28);
    $('#yearsToFINew').html(series.yearsToFI[i] + '&nbsp;years');
  };

  this.validate = function() {
    var returnval = 1;
    var empty = "required";
    if ($("#withdrawalRate").val() === '') {
       $("#withdrawalRateWarning").text(empty);
       returnval = 0;
    }
    if ($("#annualPct").val() === '') {
       $("#annualPctWarning").text(empty);
       returnval = 0;
    }
    if ($("#initialBalance").val() === '') {
       $("#initialBalanceWarning").text(empty);
       returnval = 0;
    }
    if ($("#savingsRate").val() === '') {
       $("#savingsRateWarning").text(empty);
       returnval = 0;
    }
    if ($("#annualSavings").val() === '') {
       $("#annualSavingsWarning").text(empty);
       returnval = 0;
    }
    if ($("#annualExpenses").val() === '') {
       $("#annualExpensesWarning").text(empty);
       returnval = 0;
    }
    if ($("#income").val() === '') {
       $("#incomeWarning").text(empty);
       returnval = 0;
    }

    if ($("#withdrawalRate").val() !== '') {
       $("#withdrawalRateWarning").text('');
    }
    if ($("#annualPct").val() !== '') {
       $("#annualPctWarning").text('');
    }
    if ($("#initialBalance").val() !== '') {
       $("#initialBalanceWarning").text('');
    }
    if ($("#savingsRate").val() !== '') {
       $("#savingsRateWarning").text('');
    }
    if ($("#annualSavings").val() !== '') {
       $("#annualSavingsWarning").text('');
    }
    if ($("#annualExpenses").val() !== '') {
       $("#annualExpensesWarning").text('');
    }
    if ($("#income").val() !== '') {
       $("#incomeWarning").text('');
    }

    return returnval;
  };

  this.displayAllValues = function() {
    var inputs = ["savingsRate", "withdrawalRate", "annualPct", "initialBalance", "income", "annualSavings", "annualExpenses"];
    for (var k = 0; k < inputs.length; k++) {
        var name = inputs[k];
        $("#"      + name).val(that[name] * 1);
        $("input#" + name).val(that[name] * 1);
    }

    $('span#savingsRate'    ).html(that.savingsRate + '%'        );
    $('span#yearsToFI'      ).html(that.yearsToFI + '&nbsp;years');
    $('span#annualExpenses' ).html(that.annualExpenses.toMoney() );
    $('span#annualSavings'  ).html(that.annualSavings.toMoney()  );
    $('span#monthlyExpenses').html(that.monthlyExpenses.toMoney());
    $('span#monthlySavings' ).html(that.monthlySavings.toMoney() );

    // update location url
    var url  = '/calculator/earlyretirement';
        url += '?income='         + that.income;
        url += '&initialBalance=' + that.initialBalance;
        url += '&expenses='       + that.annualExpenses;
        url += '&annualPct='      + that.annualPct;
        url += '&withdrawalRate=' + that.withdrawalRate;
    window.history.pushState('', 'Early Retirement Calculator', url);
  };

  this.incomeRecalculate = function() {
    this.annualSavings   = Math.round(100 * (this.income - this.annualExpenses)) / 100;
    that.savingsRate     = Math.round((that.annualSavings / that.income) * 100 / 2) * 2;
  };

  this.annualSavingsRecalculate = function() {
    that.annualExpenses  = Math.round(100 * (that.income - that.annualSavings)) / 100;
    that.savingsRate     = Math.round((that.annualSavings * 100 / that.income) / 2) * 2;
  };

  this.annualExpensesRecalculate = function() {
    this.annualSavings   = Math.round(100 * (this.income - this.annualExpenses)) / 100;
    that.savingsRate     = Math.round(((that.income - that.annualExpenses) * 100 / that.income) / 2) * 2;
  };

  this.savingsRateRecalculate = function() {
    that.annualExpenses  = Math.round(that.income * (1 - (that.savingsRate / 100)));
    this.annualSavings   = Math.round(100 * (this.income - this.annualExpenses)) / 100;
  };

  this.initialBalanceRecalculate = function() {};
  this.annualPctRecalculate      = function() {};
  this.withdrawalRateRecalculate = function() {};

  this.blurHandler = function() {
    var name = $(this).attr('id');

    if ($(this).val() === that[name] + '') {
        return;
    }

    var valid = that.validate();
    if (!valid) {
      return 0;
    }

    var value = N.getCleanValue(name);
    if (value === '' ) {
      $('#' + name + 'Warning').text('something did not work');
      return 0;
    }

    that[name] = value * 1;
    that[name + 'Recalculate']();

    that.redrawGraph();
  };

  this.resizeHandler = function() {
    $("#placeholder div.countries").remove();

    that.plot.resize();
    that.plot.setupGrid();

    var series = that.plot.getData()[0];

    var uk = that.plot.pointOffset({x:  1.1, y: 2});
    var us = that.plot.pointOffset({x:  5.1, y: 2});
    var de = that.plot.pointOffset({x: 11.1, y: 2});
    var fr = that.plot.pointOffset({x: 15.0, y: 2});
    var ch = that.plot.pointOffset({x: 27.1, y: 2});
    var id = that.plot.pointOffset({x: 31.1, y: 2});

    $("#placeholder").append("<div class='countries' style='left:" + uk.left + 'px;top:' + uk.top + "px;'>United Kingdom*</div>");
    $("#placeholder").append("<div class='countries' style='left:" + us.left + 'px;top:' + us.top + "px;'>United States*</div>");
    $("#placeholder").append("<div class='countries' style='left:" + de.left + 'px;top:' + de.top + "px;'>Germany*</div>");
    $("#placeholder").append("<div class='countries' style='left:" + fr.left + 'px;top:' + fr.top + "px;'>France*</div>");
    $("#placeholder").append("<div class='countries' style='left:" + ch.left + 'px;top:' + ch.top + "px;'>China*</div>");
    $("#placeholder").append("<div class='countries' style='left:" + id.left + 'px;top:' + id.top + "px;'>India*</div>");
  }

  this.plot = $.plot($("#placeholder"), this.generateGraphData(), this.plotOptions);

  $("#placeholder").bind("plotclick", this.handlePlotClick);
  $("#placeholder").bind("plothover", this.handlePlotHover);
  $("#fiButton"   ).bind('click',     this.redrawGraph);

  $("#placeholder").resize(this.resizeHandler);

  $("input#income"        ).bind('blur', this.blurHandler);
  $("input#annualSavings" ).bind('blur', this.blurHandler);
  $("input#annualExpenses").bind('blur', this.blurHandler);
  $("input#savingsRate"   ).bind('blur', this.blurHandler);
  $("input#initialBalance").bind('blur', this.blurHandler);
  $("input#annualPct"     ).bind('blur', this.blurHandler);
  $("input#withdrawalRate").bind('blur', this.blurHandler);

  this.assumptionsHidden = true;
  $("#moreAssumptions").bind('click', function () {
    if (that.assumptionsHidden) {
      $("#assumptions").show('fast');
      $('#moreAssumptions').html('Hide assumptions');
      that.assumptionsHidden = false;
    }
    else {
      $("#assumptions").hide('fast');
      $('#moreAssumptions').html('Show assumptions');
      that.assumptionsHidden = true;
    }
    return false;
  });

  this.optionsHidden = true;
  $("#controlPanel").bind('click', function () {
    if (that.optionsHidden) {
      $(".moreOptions").show('fast');
      $('#controlPanel').html('- Show less options');
      $.cookie('fi-more-options', 1);
      that.optionsHidden = false;
    }
    else {
      $(".moreOptions").hide('fast');
      $('#controlPanel').html('+ Show more options');
      $.removeCookie('fi-more-options');
      that.optionsHidden = true;
    }
    return false;
  });

  if ($.cookie('fi-more-options')) {
    $(".moreOptions").show();
    $('#controlPanel').html('- Show less options');
    $.cookie('fi-more-options', 1);
    this.optionsHidden = false;
  }

  that.annualExpensesRecalculate();
  that.redrawGraph();
  that.table.redraw();
};
