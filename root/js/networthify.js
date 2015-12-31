Number.prototype.toMoney = function(decimals, decimal_sep, thousands_sep) {
   var n = this;
   var c = isNaN(decimals) ? 0 : Math.abs(decimals);
   var d = decimal_sep || '.';
   var t = (typeof thousands_sep === 'undefined') ? ',' : thousands_sep;
   var sign = (n < 0) ? '-' : '';

   // absolute value of the integer part of the number and convert to a string
   var i = parseInt(n = Math.abs(n).toFixed(c), 10) + '';

   var j = ((j = i.length) > 3) ? j % 3 : 0;

   return sign + (j ? i.substr(0, j) + t : '') + i.substr(j).replace(/(\d{3})(?=\d)/g, "$1" + t) + (c ? d + Math.abs(n - i).toFixed(c).slice(2) : '');
};

var N = {};

N.getCleanValue = function(name) {
  var v = $('input#' + name).val();
  v = v.replace(/^\./, '0.');
  v = v.replace(/^[^0-9\-]*/, '');
  v = v.replace(/\D*$/, '');
  v = v.replace(/,/g, '');
  return v;
};
