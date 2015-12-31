use strict;
use warnings;

use Plack::Builder;
use Networth::Plack;

builder {
    mount '/' => Networth::Plack->psgi_app;
}

