var RealCost = {};

RealCost.generateData = function () {
  RealCost.data[0].data  = [];
  RealCost.data[0].price = [];
  RealCost.data[0].time  = [];

  var price        = RealCost.price;
  var interestRate = RealCost.interest / 100 / 12;

  if (RealCost.period === 'annual') {
    price = price / 12;
  }
  if (RealCost.period === 'weekly') {
    price = price * 52 / 12;
  }
  if (RealCost.period === 'daily') {
    price = price * 365 / 12;
  }

  for (var i = 0; i <= 10; i = i + 1) {
      var value = price * (Math.pow(1 + interestRate, i * 12) - 1) / interestRate;
      RealCost.data[0].data.push([i,value]);
      RealCost.data[0].price.push(Math.round(value * 10) / 10);
      RealCost.data[0].time.push(i);
  }

  return RealCost.data;
};

RealCost.egg = function () {
  var price    = RealCost.price;
  var interest = RealCost.withdrawalRate / 100 / 12;

  if (RealCost.period === 'annual') {
    price = price / 12;
  }
  if (RealCost.period === 'weekly') {
    price = price * 52 / 12;
  }
  if (RealCost.period === 'daily') {
    price = price * 365 / 12;
  }

  // egg * interest = price
  // egg = price / interest
  var egg = price / interest;
  return egg;
};

RealCost.plotOptions = {
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
  hooks      : {draw : function (p, canvas) {
      var series = p.getData()[0];
      var axisx = series.xaxis, axisy = series.yaxis;

      var offset = p.getPlotOffset();
      canvas.save();
      canvas.translate(offset.left, offset.top);

      var ps = series.datapoints.pointsize;
      var pt = series.datapoints.points.slice(RealCost.index * ps, (RealCost.index + 1) * ps);
      var x  = pt[0];
      var y  = pt[1];

      var left   = axisx.p2c(x - 0.5);
      var right  = axisx.p2c(x + 0.5);
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
    }
  }
};

RealCost.redrawGraph = function () {
  var data                 = RealCost.generateData();
  RealCost.index           = Math.round(RealCost.time);
  RealCost.realPrice       = data[0].price[RealCost.index];
  RealCost.plot            = $.plot($("#placeholder"), data, RealCost.plotOptions);
  RealCost.displayAllValues();
  // RealCost.table.redraw();
};

RealCost.handlePlotClick = function (event, pos, item) {
  if (pos.x < 0 || pos.x > 11) {
    return;
  }

  if (pos.x === 11) {
    pos.x = 10;
  }

  var series = RealCost.plot.getData()[0];

  RealCost.index           = Math.round(pos.x);
  RealCost.realPrice       = series.price[RealCost.index];
  RealCost.time            = series.time[RealCost.index];
  RealCost.plot            = $.plot($("#placeholder"), RealCost.data, RealCost.plotOptions);
  RealCost.placeLabels(pos);

  RealCost.displayAllValues();
  // RealCost.table.redraw();
};

RealCost.handlePlotHover = function (event, pos, item) {
  if (pos.x < 1 || pos.x > 10) {
      return;
  }

  var series = RealCost.plot.getData()[0];
  var i = Math.round(pos.x);

  RealCost.placeLabels(pos);

  for (var j = 0; j < series.data.length; j++) {
      RealCost.plot.unhighlight(series, j);
  }
  RealCost.plot.highlight(series, i);
};

RealCost.placeLabels = function(pos) {
  $('#timeNew').remove();
  $('#priceNew').remove();

  $('#placeholder').append(
    '<span id="timeNew"></span><span id="priceNew"></span>'
  );

  var series = this.plot.getData()[0];
  var i = Math.round(pos.x);
  var x = Math.round(pos.x);
  var xlabel = this.plot.pointOffset({x: x, y: this.plot.getAxes().yaxis.min});
  var ylabel = this.plot.pointOffset({x: this.plot.getAxes().xaxis.min, y: series.price[i]});

  $('#timeNew').attr('class', 'calculatorGraphLabel');
  $('#timeNew').css('position', 'absolute');
  $('#timeNew').css('top', xlabel.top + 6);
  $('#timeNew').css('left', xlabel.left - 34);
  $('#timeNew').html(series.time[i] + '&nbsp; years');

  $('#priceNew').attr('class', 'calculatorGraphLabel');
  $('#priceNew').css('position', 'absolute');
  $('#priceNew').css('top', ylabel.top - 7);
  $('#priceNew').css('left', ylabel.left - 40);
  $('#priceNew').html(series.price[i].toFixed(0));
};

RealCost.validate = function() {
  var returnval = 1;
  var empty = "required";
  if ($("#price").val() === '') {
     $("#priceWarning").text(empty);
     returnval = 0;
  }
  if ($("#interest").val() === '') {
     $("#interestWarning").text(empty);
     returnval = 0;
  }

  if ($("#price").val() !== '') {
     $("#priceWarning").text('');
  }
  if ($("#interest").val() !== '') {
     $("#interestWarning").text('');
  }

  return returnval;
};

RealCost.displayAllValues = function() {
  $('.sentence .price'         ).html(RealCost.price.toMoney());
  $('.sentence .period'        ).html(RealCost.period);
  $('.sentence .withdrawalRate').html(RealCost.withdrawalRate);
  $('#egg'                     ).html(RealCost.egg().toMoney());
  $('span#time'                ).html(RealCost.time + '&nbsp;years');
  $('span#price'               ).html(RealCost.realPrice.toMoney());
};

RealCost.blurHandler = function() {
  var name = $(this).attr('id');

  if ($(this).val() === RealCost[name] + '') {
      return;
  }

  var valid = RealCost.validate();
  if (!valid) {
    return 0;
  }

  var value;
  if (name === 'period') {
    value = $(this).children().filter(":selected").val();
    RealCost[name] = value;
  }
  else {
    value = N.getCleanValue(name);
    RealCost[name] = value * 1;
  }
  if (value === '' ) {
    $('#' + name + 'Warning').text('Error.  Enter a different value.');
    return 0;
  }

  //RealCost[name + 'Recalculate']();

  RealCost.redrawGraph();
};

RealCost.init = function () {
  this.price          = 10;
  this.realPrice      = 1731;
  this.period         = 'monthly';
  this.interest       = 7;
  this.withdrawalRate = 3;
  this.time           = 10;
  this.data           = [{
    color : '#999',
    bars  : {
      show      : true,
      fill      : true,
      fillColor : '#ddd',
      lineWidth : 1,
      barWidth  : 1,
      align     : 'center',
    }
  }];

  this.plot = $.plot($("#placeholder"), this.generateData(), this.plotOptions);

  $("#placeholder").bind("plotclick", this.handlePlotClick);
  $("#placeholder").bind("plothover", this.handlePlotHover);
  $("#fiButton"   ).bind('click',     this.redrawGraph);

  $("input#price"   ).bind('blur',   this.blurHandler);
  $("select#period" ).bind('blur',   this.blurHandler);
  $("select#period option" ).bind('select', this.blurHandler);
  $("input#interest").bind('blur',   this.blurHandler);

  //this.table.redraw();
};


RealCost.init();
