package Ledger::Transaction;
BEGIN {
  $Ledger::Transaction::VERSION = '0.01';
}

use 5.010;
use DateTime;
use Log::Any '$log';
use Moo;

# VERSION

my $now = DateTime->now;
my $reset_line = sub { $_[0]->line(undef) };

has date        => (is => 'rw', trigger => $reset_line);
has seq         => (is => 'rw', trigger => $reset_line);
has description => (is => 'rw', trigger => $reset_line);
has entries     => (is => 'rw');
has line        => (is => 'rw');
has journal     => (is => 'rw');

my $re_dsep = qr![/-]!;
our $re_date = qr/(?:
                      (?:(?<y>\d\d|\d\d\d\d)$re_dsep)?
                      (?<m>\d{1,2})$re_dsep
                      (?<d>\d{1,2})
                  )/x;

sub BUILD {
    my ($self, $args) = @_;
    unless ($self->entries) {
        $self->entries([]);
    }
    if (!ref($self->date)) {
        $self->date($self->_parse_date($self->date));
    }
    # re-set here because of trigger
    if (!defined($self->line)) {
        $self->line($args->{line});
    }
}

sub _parse_date {
    my ($self, $date) = @_;
    die "Invalid date" unless $date =~ $re_date;
    my $y = $+{y} // $now->year;
    DateTime->new(day => $+{d}, month => $+{m}, year => $y);
}

sub as_string {
    my ($self) = @_;
    my $rl = $self->journal->raw_lines;

    my $res = defined($self->line) ?
        $self->journal->raw_lines->[$self->line] :
            $self->date->ymd . ($self->seq ? " (".$self->seq.")" : "") . " ".
                $self->description . "\n";
    for my $p (@{$self->entries}) {
        $res .= $p->as_string;
    }
    $res;
}

sub postings {
    my ($self) = @_;
    [grep {$_->isa('Ledger::Posting')} @{$self->entries}];
}

sub _bal_or_check {
    my ($self, $which) = @_;
    my $postings = $self->postings;

    my $num_p = 0;
    my $num_v = 0;
    my $num_vnb = 0;
    my $num_blank = 0;
    my %bal; # key=commodity
    for (@$postings) {
        $num_p++;
        $num_v++ if $_->is_virtual;
        my $is_vnb;
        if ($_->is_virtual && !$_->virtual_must_balance) {
            $num_vnb++;
            $is_vnb = 1;
        }
        $num_blank++ unless $_->amount;
        my $amt = $_->amount;
        next unless $amt;
        next if $is_vnb && $which eq 'check';
        my $scalar = $amt->[0];
        my $cmdity = $amt->[1];
        $bal{$cmdity} //= 0;
        $bal{$cmdity} += $scalar;
    }

    my @bal = map {[$bal{$_},$_]} grep {$bal{$_} != 0} keys %bal;
    if ($which eq 'check') {
        my $errprefix = "Transaction at line #".($self->line+1).": ";
        die $errprefix."there must be at least 2 postings"
            if $num_p < 2 && !$num_v;
        die $errprefix."there must be at least 1 posting"
            if !$num_p;
        die $errprefix."there must be at most 1 posting with blank amount"
            if $num_blank > 1;

        unless ($num_blank) {
            die $errprefix."doesn't balance (".
                join(", ", map {$postings->[0]->format_amount($_)} @bal).")"
                    if @bal;
        }
        return 1;
    } else {
        return [] if $num_blank;
        return \@bal;
    }
}

sub balance {
    my ($self) = @_;
    $self->_bal_or_check('bal');
}

sub check {
    my ($self) = @_;
    $self->_bal_or_check('check');
}

1;
# ABSTRACT: Represent a Ledger transaction


=pod

=head1 NAME

Ledger::Transaction - Represent a Ledger transaction

=head1 VERSION

version 0.01

=head1 SYNOPSIS

=head1 DESCRIPTION

=for Pod::Coverage BUILD

=head1 ATTRIBUTES

=head2 date => DATETIME OBJ

=head2 seq => INT or undef

Sequence of transaction in a day. Optional.

=head2 description => STR

=head2 line => INT

=head2 entries => ARRAY OF OBJS

Array of L<Ledger::Posting> or L<Ledger::Comment>

=head2 journal => OBJ

Pointer to L<Ledger::Journal> object.

=head1 METHODS

=head2 new(...)

=head2 $tx->as_string()

=head2 $tx->balance() => [[SCALAR,COMMODITY], ...]

Return transaction's balance. If a transaction balances, this method should
return [].

=head2 $tx->check()

=head2 $tx->postings()

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

