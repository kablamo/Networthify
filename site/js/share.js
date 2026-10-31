// Share a link with the phone's share sheet, or copy it on computers that
// don't have one.  `note` is an element to show "Link copied" in.
window.shareLink = function (data, note) {
  'use strict';

  var say = function (msg) {
    note.textContent = msg;
    setTimeout(function () { note.textContent = ''; }, 2500);
  };
  var copy = function () {
    if (navigator.clipboard && window.isSecureContext) {
      navigator.clipboard.writeText(data.url).then(
        function () { say('Link copied'); },
        function () { window.prompt('Copy this link:', data.url); }
      );
    } else {
      window.prompt('Copy this link:', data.url);
    }
  };

  if (navigator.share) {
    navigator.share(data).catch(function (e) {
      if (e && e.name !== 'AbortError') copy();
    });
  } else {
    copy();
  }
};
