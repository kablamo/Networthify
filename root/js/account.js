$(".assets a").bind('click', function () {
    if ($('#tagSplit').css('display') !== 'none') {
      $('#tagSplit').slideUp();
      return false;
    }
    var tagName = $(this).find('.text').text();
    $('#tagSplit #tag').attr('value', tagName);

    var tagSplit = $('#tagSplit').detach();
    $(this).after(tagSplit);

    $("#cancelSplit").bind('click', function () {
        $('#tagSplit').slideUp();
        return false;
    });

    tagSplit.slideDown();

    return false;
});

// $("#datepicker").datepicker();
