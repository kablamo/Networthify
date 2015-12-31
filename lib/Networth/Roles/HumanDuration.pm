package Networth::Roles::HumanDuration;
use Moo::Role;
use Number::Format qw/format_number/;

=head1 SYNOPSIS

    with qw/Networth::Roles::HumanDuration/;

    sub foo {
        $self = shift;
        my $hours = 123;
        say $self->humanDuration(123);
    }

=cut

requires qw/workDay daysPerYear/;

sub humanDuration {
    my ($self, $hours) = @_;
    my ($yrs, $dys, $hrs, $yrsLabel, $dysLabel, $hrsLabel, $dysStr);

    my $workDay     = $self->workDay;
    my $daysPerYear = $self->daysPerYear;

    $hrsLabel = $hours > 1 ? "hrs" : "hr&nbsp;";
    return format_number($hours, 0) . $hrsLabel if $hours < $workDay;

    $dys = int($hours / $workDay);
    $hrs = $hours % $workDay;
    $dysLabel = $dys   > 1 ? "dys " : "dy&nbsp;&nbsp;";
    $hrsLabel = $hours > 1 ? "hrs" : "hr&nbsp;";
    return $dys . $dysLabel . $hrs . $hrsLabel if $dys < $daysPerYear;

    $yrs = int($dys / $daysPerYear);
    $dys = $dys % $daysPerYear;
    $yrsLabel = $yrs > 1 ? "yrs " : "yr&nbsp;&nbsp;";
    $dysLabel = $dys > 1 ? "dys " : "dy&nbsp;&nbsp;";
    $dysStr   = sprintf("%03d", $dys);
    return $yrs . $yrsLabel . $dysStr . $dysLabel . $hrs . $hrsLabel;
}

1;
