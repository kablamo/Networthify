// The top menu folds into a button on small screens.  Without JavaScript
// the links just show.
(function () {
  'use strict';

  var header = document.querySelector('header.top');
  var button = header && header.querySelector('.menu-button');
  if (!button) return;

  header.classList.add('has-menu');
  button.hidden = false;
  var setOpen = function (open) {
    header.classList.toggle('open', open);
    button.setAttribute('aria-expanded', String(open));
  };
  button.addEventListener('click', function () {
    setOpen(!header.classList.contains('open'));
  });
  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape' && header.classList.contains('open')) { setOpen(false); button.focus(); }
  });
})();
