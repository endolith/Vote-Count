use strict;
use warnings;
use 5.022;
use feature qw /postderef signatures/;

package Vote::Count::Method::CondorcetDropping;

use namespace::autoclean;
use Moose;
extends 'Vote::Count';

our $VERSION='0.005';

=head1 NAME

Vote::Count::Method::CondorcetDropping

=head1 VERSION 0.005

=cut

# ABSTRACT: Methods which use simple dropping rules to resolve a Winnerless Condorcet Matrix.

#buildpod

=pod

=head1 Condorcet Dropping Methods

This module implements dropping methodologies for resolving a Condorcet Matrix with no Winner. Dropping Methodologies apply a rule to either all remaining choices or to those with the least wins to select a choice for elimination.


=head2 Basic Dropping Methods

Common Dropping Methods are: Boorda Count (with all the attendant weighting issues), Approval, Plurality Loser (TopCount), and Greatest Loss. Greatest Loss is not currently available, and will likely be implemented in the SSD module if and when that is ever written.


=head1 SYNOPSIS

=cut

#buildpod

no warnings 'experimental';
use List::Util qw( min max );
# use YAML::XS;

use Vote::Count::Matrix;
use Carp;
# use Try::Tiny;
# use Text::Table::Tiny 'generate_markdown_table';
# use Data::Printer;
# use Data::Dumper;

has 'Matrix' => (
  isa => 'Object',
  is => 'ro',
  lazy => 1,
  builder => '_newmatrix',
);

# DropStyle: whether to apply drop rule against
# all choices ('all') or the least winning ('leastwins').
has 'DropStyle' => (
  isa => 'Str',
  is => 'ro',
  default => 'leastwins',
);

has 'DropRule' => (
  isa => 'Str',
  is => 'ro',
  default => 'plurality',
);

sub GetRound ( $self, $active, $roundnum='' ) {
  my $rule = lc( $self->DropRule() );
  if ( $rule =~ m/(plurality|topcount)/ ) {
    return $self->TopCount($active);
  }
  elsif ( $rule eq 'approval' ) {
    my $round = $self->Approval($active);
    $self->logv( "Round $roundnum Approval Totals ", $round->RankTable() );
    return $round;
  }
  elsif ( $rule eq 'boorda' ) {
    my $round = $self->Boorda($active);
    $self->logv( "Round $roundnum Boorda Count ", $round->RankTable() );
    return $round;
  }
  elsif ( $rule eq 'greatestloss' ) {
    ...;
  }
  else {
    croak "undefined dropping rule $rule requested";
  }
}

sub DropChoice ( $self, $round, @jeapardy ) {
  my %roundvotes = $round->RawCount()->%*;
  my @eliminate  = ();
  my $lowest     = $round->CountVotes();
  for my $j (@jeapardy) {
    $lowest = $roundvotes{$j} if $roundvotes{$j} < $lowest;
  }
  for my $j (@jeapardy) {
    if ( $roundvotes{$j} == $lowest ) {
      push @eliminate, $j;
    }
  }
  return @eliminate;
}

sub _newmatrix ($self) {
  return Vote::Count::Matrix->new(
    'BallotSet' => $self->BallotSet()  );
}

sub _logstart( $self, $active ) {
  my $dropdescription = 'Elimination Rule is Applied to All Active Choices.';
  if( $self->DropStyle eq 'leastwins') {
    $dropdescription =
      'Elimination Rule is Applied to only Choices with the Fewest Wins.';
  }
  my $rule = '';
  if ( $self->DropRule() =~ m/(plurality|topcount)/ ) {
    $rule = "Drop the Choice With the Lowest TopCount.";
  }
  elsif ( $self->DropRule() eq 'approval' ) {
    $rule = "Drop the Choice With the Lowest Approval.";
  }
  elsif ( $self->DropRule() eq 'boorda' ) {
    $rule = "Drop the Choice With the Lowest Borda Score.";
  }
  elsif ( $self->DropRule() eq 'greatestloss' ) {
    $rule = "Drop the Choice With the Greatest Loss.";
  }
  else {
    croak "undefined dropping rule $rule requested";
  }
  $self->logt( 'CONDORCET SEQUENTIAL DROPPING METHOD',
    'CHOICES:',
    join( ', ', (sort keys %{$active}) ) );
  $self->logv( "Elimination Rule: $rule", $dropdescription );
}

sub RunCondorcetDropping ( $self, $active = undef ) {
  unless ( defined $active ) { $active = $self->BallotSet->{'choices'} }
  my $roundctr   = 0;
  my $maxround   = scalar( keys %{$active} );
  $self->_logstart( $active);
DROPLOOP:
  until ( 0 ) {
    $roundctr++;
    die "DROPLOOP infinite stopped at $roundctr" if $roundctr > $maxround;
    my $topcount = $self->TopCount( $active );
    my $round = $self->GetRound( $active, $roundctr );
    $self->logv( '---', "Round $roundctr TopCount", $topcount->RankTable() );
    my $majority = $self->EvaluateTopCountMajority( $topcount );
    if ( defined $majority->{'winner'} ) {
      return $majority->{'winner'};
    }
    my $matrix = Vote::Count::Matrix->new(
      'BallotSet' => $self->BallotSet,
      'Active' => $active );
    $self->logv( '---', "Round $roundctr Pairings", $matrix->MatrixTable() );
    my $cw = $matrix->CondorcetWinner() || 0 ;
    if ( $cw ) {
      my $wstr = "*  Winner $cw  *";
      my $rpt = length( $wstr) ;
      $self->logt( '*'x$rpt, $wstr, '*'x$rpt );
      return $cw;
    }
    my $eliminated = $matrix->CondorcetLoser();
    if( $eliminated->{'eliminations'}) {
      # tracking active between iterations of matrix.
      $active = $matrix->Active();
      $self->logv( "Eliminated Condorcet Losers:",
        join( ', ', $eliminated->{'eliminated'}->@* ));
      # active changed, restart loop
      next DROPLOOP;
    }
    my @jeapardy = ();
    if( $self->DropStyle eq 'leastwins') {
      @jeapardy = $matrix->LeastWins();
    } else { @jeapardy = keys %{$active} }
    for my $goodbye ( $self->DropChoice( $round, @jeapardy )) {
      delete $active->{ $goodbye };
      $self->logv( "Elimminating $goodbye");
    }
    my @remaining = keys $active->%* ;
    if ( @remaining == 0) {
      $self->logt( "All remaining Choices would be eliminated, Tie between @jeapardy");
      return 'tie';
      $self->{'tied'} = \@jeapardy;
    } elsif ( @remaining == 1) {
      my $winner = $remaining[0];
      $self->logt( "Only 1 choice remains.", "** WINNER : $winner **");
      return $winner;
    }
  };#infinite DROPLOOP

  }


1;