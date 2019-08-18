use strict;
use warnings;
use 5.022;

use feature qw /postderef signatures/;

package Vote::Count::TieBreaker;
use Moose::Role;

no warnings 'experimental';
use List::Util qw( min max sum );
use Data::Printer;

our $VERSION='0.021';

=head1 NAME

Vote::Count::TieBreaker

=head1 VERSION 0.021

=cut

# ABSTRACT: TieBreaker object for Vote::Count. Toolkit for vote counting.

=head1 Tie Breakers

The most important thing for a Tie Breaker to do is it should use some reproducable difference in the Ballots to pick a winner from a Tie. The next thing it should do is make sense. Finally, the ideal Tie Breaker will resolve when there is any difference to be found. Arguably the best use of Borda Count is as a Tie Breaker, First Choice votes and Approval are also other great choices.

=head1 Grand Junction

The Grand Junction (also known as Bucklin) method is one of the simplest and easiest to Hand Count RCV resolution methods. Other than that it is generally not considered a good method.

Because it is simple, and always resolves, except when ballots are perfectly matched up, it is a really

=head2 The (Standard) Grand Junction Method

=over

=item 1

Count the Ballots to determine the quota for a majority.

=item 2

Count the first choices and elect a choice which has a majority.

=item 3

If there is no winner add the second choices to the totals and elect the choice which has a majority (or the most votes if more than one choice reaches a majority).

=item 4

Keep adding the next rank to the totals until either there is a winner or all ballots are exhausted.

=item 5

When all ballots are exhausted the choice with the highest total wins.

=back

=head2 As a Tie Breaker

The Tie Breaker Method is modified.

Instead of Majority, any choice with a current total less than another is eliminated.

The winner is the last choice remaining.

head2 TieBreakerGrandJunction

  my $resolve = $Election->TieBreakerGrandJunction( $choice1, $choice2  );
  if ( $resolve->{'winner'}) { say "Tie Winner is $resolve->{'winner'}"}
  elsif ( $resolve->{'tie'}) {
    my @tied = $resolve->{'tied'}->@*;
    say "Still tied between @tied."
  }

The Tie Breaking will be logged to the verbose log, any number of tied choices may be provided.

=cut

sub TieBreakerGrandJunction ( $self, @choices ) {
  my $ballots  = $self->BallotSet()->{'ballots'};
  my %current  = ( map { $_ => 0 } @choices );
  my $deepest = 0;
  for my $b ( keys $ballots->%* ) {
    my $depth = scalar $ballots->{$b}{'votes'}->@*;
    $deepest = $depth if $depth > $deepest;
  }
  my $round = 1;
  while ( $round <= $deepest ) {
    $self->logv( "Tie Breaker Round: $round");
    for my $b ( keys $ballots->%* ) {
      my $pick = $ballots->{$b}{'votes'}[$round -1] or next ;
      if ( defined $current{$pick} ) {
        $current{$pick} += $ballots->{$b}{'count'};
      }
    }
    my $max = max( values %current );
    for my $c ( sort @choices ) { $self->logv( "\t$c: $current{$c}") }
    for my $c ( sort @choices ) {
      if ( $current{$c} < $max ) {
        delete $current{$c};
        $self->logv( "Tie Breaker $c eliminated");
      }
    }
    @choices = ( sort keys %current );
    if ( 1 == @choices ) {
      $self->logv( "Tie Breaker Won By: $choices[0]");
      return { 'winner' => $choices[0], 'tie' => 0, 'tied' =>[]  };
    }
    $round++;
  }
return { 'winner' => 0, 'tie' => 1, 'tied' => \@choices };
}

1;

#FOOTER

=pod

BUG TRACKER

L<https://github.com/brainbuz/Vote-Count/issues>

AUTHOR

John Karr (BRAINBUZ) brainbuz@cpan.org

CONTRIBUTORS

Copyright 2019 by John Karr (BRAINBUZ) brainbuz@cpan.org.

LICENSE

This module is released under the GNU Public License Version 3. See license file for details. For more information on this license visit L<http://fsf.org>.

=cut