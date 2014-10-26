package Ledger::Util;
BEGIN {
  $Ledger::Util::VERSION = '0.02';
}

use 5.010;
use strict;
use warnings;
use Exporter::Lite;
use Parse::Number::EN qw(parse_number_en);

our @EXPORT    = qw($re_cmdity $re_comment $re_date $re_amount $re_number
                    $re_accpart $re_account0 $re_account $reset_lineref_sub);
our @EXPORT_OK = qw(parse_number);

our $reset_lineref_sub = sub { $_[0]->lineref(undef) };

our $re_comment   = qr/^(\s*;|[^0-9P]|\s*$)/x;
our $re_cmdity    = qr/(?:[A-Za-z_]\w+|\$)/x; # XXX add other currency symbols
my  $re_dsep      = qr![/-]!;
our $re_date      = qr/(?:
                           (?:(?<y>\d\d|\d\d\d\d)$re_dsep)?
                           (?<m>\d{1,2})$re_dsep
                           (?<d>\d{1,2})
                       )/x;
our $re_number    = $Parse::Number::EN::Pat;
our $re_amount    = qr/(?:
                           (?:(?<cmdity>$re_cmdity)\s*(?<number>$re_number))|
                           (?:(?<number>$re_number)\s*(?<cmdity>$re_cmdity))|
                           (?:(?<number>$re_number))
                       )/x;
our $re_accpart   = qr/(?:(
                              (?:[^:\s]+[ \t][^:\s]*)|
                              [^:\s]+
                      ))+/x; # don't allow double space
our $re_account0  = qr/(?:$re_accpart(?::$re_accpart)*)/x;
our $re_account   = qr/(?<acc>$re_account0|\($re_account0\)|\[$re_account0\])/x;

sub parse_number {
    my $num = shift;
    $num =~ $re_number ? $num+0 : undef;
}

sub now {
    my $self = shift;
    state $mtime;
    state $cache;
    my $now = time;

    # cache "now" every hour
    if (!$mtime || $now-$mtime > 3600) {
        $cache = DateTime->now;
        $mtime = $now;
    }
    $cache;
}

sub parse_date {
    my ($date) = @_;
    die("Invalid date `$date`") unless $date =~ $re_date;
    my $y = $+{y} // now->year;
    DateTime->new(day => $+{d}, month => $+{m}, year => $y);
}

sub parse_amount {
    my ($amt) = @_;
    $amt =~ $re_amount or die("Invalid amount syntax `$amt`");
    my $number = $+{number};
    my $cmdity = $+{cmdity} // "";
    $number = parse_number_en(text => $+{number});
    [$number, $cmdity];
}

sub format_amount {
    my ($amt) = @_;
    $amt->[0] . (length($amt->[1]) ? " $amt->[1]" : "");
}

1;

__END__
=pod

=head1 NAME

Ledger::Util

=head1 VERSION

version 0.02

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

