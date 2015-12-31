package Networth::Plack;
use v5.19.6;
use Plack::Builder;
use Plack::Response;
use Networth;
use Networth::Utils;
use Log::Dispatch;

sub psgi_app {
    my $logger = logger();

    builder {
        enable "AccessLog::Timed", 
            format => "%h %t %>s %r %b %D", 
            logger => sub {$logger->debug(@_)};

        enable 'Rewrite', rules => sub {
            s|^/calculator/retirementcalculator|/calculator/earlyretirement|;
            s|^/calculator/financialindependence|/calculator/earlyretirement|;
            s|^/calculator/fi|/calculator/earlyretirement|;
            s|^/calculator/real-cost|/calculator/recurring-charges|;
            return;
        };

        enable "Deflater",
            vary_user_agent => 1,
            content_type    => ['text/css','text/javascript','application/javascript'];

        enable "Assets", # 0 - /calculator/fi.tt
            expires => 60 * 60 * 24 * 365, # 1 year
            minify  => 1,
            files   => [
                "root/js/flot/jquery.flot.js",
                "root/js/flot/jquery.flot.navigate.js",
                "root/js/flot/jquery.flot.resize.js",
                "root/js/networthify.js",
                "root/js/fi.start.js",
                "root/js/fi.math.js",
                "root/js/fi.table.js",
                "root/js/fi.plot.js",
            ],
        ;
        enable "Assets", # 1 -- NOT USED -- TODO: DELETEME
            expires => 60 * 60 * 24 * 365, # 1 year
            minify  => 1,
            files   => [
                "root/js/flot/jquery.flot.js",
                "root/js/flot/jquery.flot.selection.js",
                "root/js/flot/jquery.flot.navigate.js",
                "root/js/flot/jquery.flot.resize.js",
            ],
        ;
        enable "Assets", # 2 -- header.tt, index.tt
            expires => Networth::Utils->dev_mode 
                ? 1                   # 1 second
                : 60 * 60 * 24 * 365, # 1 year
            minify  => 1,
            files   => [
                "root/css/minireset.css",
                "root/css/networthify.css",
            ],
        ;
        enable "Assets", # 3 -- NOT USED -- TODO: DELETEME
            expires => 60 * 60 * 24 * 365, # 1 year
            minify  => 1,
            files   => [
                "root/css/minireset.css",
            ],
        ;
        enable "Assets", # 4 -- import.tt, import.columns.tt
            expires => 60 * 60 * 24 * 365, # 1 year
            minify  => 1,
            files   => [
                "root/upload/js/vendor/jquery.ui.widget.js",
                "root/upload/js/jquery.iframe-transport.js",
                "root/upload/js/jquery.fileupload.js",
                "root/upload/js/jquery.fileupload-ui.js",
                "root/upload/js/locale.js",
            ],
        ;
        enable "Assets", # 5 -- header.tt (for import)
            expires => 60 * 60 * 24 * 365, # 1 year
            minify  => 1,
            files   => [
                "root/upload/css/jquery.fileupload-ui.css",
                "root//css/jquery-ui-1.8.23.smoothness.css",
                "root/css/import.css",
            ],
        ;

        enable "Static", root => 'root/', path => 'css/minireset.css',                  ;
        enable "Static", root => 'root/', path => 'css/networthify.css',                ;
        enable "Static", root => 'root/', path => 'css/style.less',                     ;
        enable "Static", root => 'root/', path => 'font/icons.eot',                     ;
        enable "Static", root => 'root/', path => 'font/icons.svg',                     ;
        enable "Static", root => 'root/', path => 'font/icons.ttf',                     ;
        enable "Static", root => 'root/', path => 'font/icons.woff',                    ;
        enable "Static", root => 'root/', path => 'googlebd4e59492976fb15.html',        ;
        enable "Static", root => 'root/', path => 'img/calendar.png',                   ;
        enable "Static", root => 'root/', path => 'img/loading.gif',                    ;
        enable "Static", root => 'root/', path => 'img/logout.png',                     ;
        enable "Static", root => 'root/', path => 'img/money.png',                      ;
        enable "Static", root => 'root/', path => 'img/moneybag.png',                   ;
        enable "Static", root => 'root/', path => 'img/navy_blue.png',                  ;
        enable "Static", root => 'root/', path => 'img/noisy_grid.png',                 ;
        enable "Static", root => 'root/', path => 'img/progressbar.gif',                ;
        enable "Static", root => 'root/', path => 'img/settings.png',                   ;
        enable "Static", root => 'root/', path => 'img/wood_pattern.png',               ;
        enable "Static", root => 'root/', path => 'js/account.js',                      ;
        enable "Static", root => 'root/', path => 'js/flot/excanvas.min.js',            ;
        enable "Static", root => 'root/', path => 'js/jquery-1.7.2.min.js',             ;
        enable "Static", root => 'root/', path => 'js/jquery-1.8.23.datepicker.min.js', ;
        enable "Static", root => 'root/', path => 'js/jquery.mailcheck.min.js',         ;
        enable "Static", root => 'root/', path => 'js/less-1.2.1.min.js',               ;
        enable "Static", root => 'root/', path => 'js/jquery.cookie.js',                ;
        enable "Static", root => 'root/', path => 'js/d3.min.js',                       ;
        enable "Static", root => 'root/', path => 'js/justgage.js',                     ;
        enable "Static", root => 'root/', path => 'upload/img/loading.gif',             ;
        enable "Static", root => 'root/', path => 'upload/img/progressbar.gif',         ;

        Networth->psgi_app;
    }
}

sub logger {
    my @outputs;
    push @outputs, [  'File', min_level => 'debug', filename => 'access', mode => 'append'];
    push @outputs, ['Screen', min_level => 'debug', stderr   => 1]
        if Networth::Utils->dev_mode;

    return Log::Dispatch->new(outputs => \@outputs);
}

1;
