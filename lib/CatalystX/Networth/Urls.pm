package CatalystX::Networth::Urls;
use Moose::Role;
use DateTime;

sub urls {
    {
        base       => urlBase(@_),
        firstPart  => firstPart(@_),
        datePart   => datePart(@_),
        next       => urlNext(@_),
        prev       => urlPrev(@_),
    };
}

sub urlBase {
    my ($c, $accountId, $name, $when) = @_;
    my $startDate = $when->{start}->ymd;
    my $endDate   = $when->{end}->ymd;
    return "$accountId/$name/$startDate/$endDate";
}

sub firstPart {
    my ($c, $accountId, $name, $when, $first) = @_;
    return $first;
}

sub datePart {
    my ($c, $accountId, $name, $when, $first) = @_;
    my $startDate = $when->{start}->ymd;
    my $endDate   = $when->{end}->ymd;
    return "$startDate/$endDate";
}

sub urlNext { 
    my ($c, $accountId, $name, $when, $first) = @_;
    my $startDate = $when->{nextStart}->ymd;
    my $endDate   = $when->{nextEnd}->ymd;
    return "/$first/$accountId/$name/$startDate/$endDate";
}

sub urlPrev { 
    my ($c, $accountId, $name, $when, $first) = @_;
    my $startDate = $when->{prevStart}->ymd;
    my $endDate   = $when->{prevEnd}->ymd;
    return "/$first/$accountId/$name/$startDate/$endDate";
}


1;
