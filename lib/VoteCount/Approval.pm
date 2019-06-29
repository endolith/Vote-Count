use strict;
use warnings;
use 5.026;

use feature qw /postderef signatures/;

package VoteCount::Approval;
use Moose::Role;

no warnings 'experimental';
use Data::Printer;

sub Approval ( $self, $active=undef ) {
  my %ballotset = $self->ballotset()->%*;
  my %ballots = ( $ballotset{'ballots'}->%* );
# p %ballots;
  $active = $ballotset{'choices'} unless defined $active ;
# p $active;
  my %approval = ( map { $_ => 0 } keys( $active->%* ));
    for my $b ( keys %ballots ) {
# warn "checkijng $b";
# p $ballots{$b};
# return {};
      my @votes = $ballots{$b}->{'votes'}->@* ;
      for my $v ( @votes ) {
        if ( defined $approval{$v} ) {
          $approval{$v} += $ballots{$b}{'count'};
        }
      }
    }
  return \%approval;
}

1;