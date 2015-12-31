FI.Table = function () {
  var that = this;
  var undefined;


  this.redraw = function () {
    var html = '  <tr>' +
               '    <th>End Of Year</th>' +
               '    <th>Income</th>' +
               '    <th>Expenses</th>' +
               '    <th>' + that.annualPct + '% Return On Investments (ROI)</th>' +
               '    <th>Percent Of Expenses Covered By ROI</th>' +
               '    <th>Change In Networth (Savings + ROI)</th>' +
               '    <th>Networth</th>' +
               '  </tr>';
    html += '    <tr>' +
                    '<td>0</td>' +
                    '<td>-</td>' +
                    '<td>-</td>' +
                    '<td>-</td>' +
                    '<td>-</td>' +
                    '<td>-</td>' +
                    '<td>' + that.initialBalance.toMoney() + '</td>' +
                '</tr>';

    if (!isFinite(that.yearsToFI)) {
        $("table#fi").html(html);
        return;
    }

    var portfolio       = that.initialBalance;
    var expenses        = that.annualExpenses;
    var equal           = 0;

    for (var i = 1; i <= Math.ceil(that.yearsToFI); i++) {
        var rturn = Math.round((portfolio + that.annualSavings/2) * that.annualPct / 100);
        var savings = rturn + that.annualSavings;
        portfolio += savings;

        var pctOfExpenses = Math.round( (rturn / expenses) * 100);

        if (equal == 0 && expenses <= rturn) {
            equal = i;
        }

        var div = '<div style="width: 25%; padding: .5em; float: left">' + pctOfExpenses + '%</div>' +
                  '<div style="float: left; height: 2.2em; width: 50%">' +
                  '  <div style="height: 2.2em; background: #ccc; float: left; width: ' + pctOfExpenses + '%"></div>' +
                  '  <div style="height: 2.2em; background: #eee; float: left; width: ' + (100 - pctOfExpenses) + '%"></div>' +
                  '</div>';
        html += '    <tr>' +
                       '<td>' + i + '</td>' +
                       '<td>' + that.income.toMoney() + '</td>' +
                       '<td>' + expenses.toMoney() + '</td>' +
                       '<td>' + rturn.toMoney() + '</td>' +
                       '<td style="padding: 0">' + div + '</td>' +
                       '<td>' + savings.toMoney() + '</td>' +
                       '<td>' + portfolio.toMoney() + '</td>' +
                    '</tr>';
    }

    $("table#fi").html(html);

    var color = '#fff';
    for (var i = Math.ceil(that.yearsToFI) + 1; i > equal; i--) {
        var row = $("table#fi tr").eq(i);
        row.find("td").eq(2).css('background', '#' + color).css('color', '#fff');
        row.find("td").eq(3).css('background', '#' + color).css('color', '#fff');
        row.find("td").eq(4).css('background', '#' + color).css('color', '#fff');
    }
  };

  return this;
};
