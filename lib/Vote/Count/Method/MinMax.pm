use strict;
use warnings;
use 5.022;
use feature qw /postderef signatures/;

package Vote::Count::Method::MinMax;

use namespace::autoclean;
use Moose;
extends 'Vote::Count::Matrix';
with 'Vote::Count::Floor';

our $VERSION = '1.06';

=head1 NAME

Vote::Count::Method::MinMax

=head1 VERSION 1.06

=cut

# ABSTRACT: Methods in the MinMax Family.

=pod

=head1 SYNOPSIS

 my $MinMaxElection =
 Vote::Count::Method::MinMax->new(
  'BallotSet' => $ballotset ,
  'DropStyle' => 'all',
  'DropRule' => 'topcount',
 );

 my $Winner = $CondorcetElection->RunCondorcetDropping( $SmithSet )->{'winner'};

=head1 Shameless Piracy of Electowiki

Minmax or Minimax (Simpson-Kramer method) is the name of several election methods based on electing the candidate with the lowest score, based on votes received in pairwise contests with other candidates.

Minmax(winning votes) elects the candidate whose greatest pairwise loss to another candidate is the least, when the strength of a pairwise loss is measured as the number of voters who voted for the winning side.

Minmax(margins) is the same, except that the strength of a pairwise loss is measured as the number of votes for the winning side minus the number of votes for the losing side.

Criteria passed by both methods: Condorcet criterion, majority criterion

Criteria failed by both methods: Smith criterion, mutual majority criterion, Condorcet loser criterion.

Minmax(winning votes) also satisfies the Plurality criterion. In the three-candidate case, Minmax(margins) satisfies the Participation criterion.

Minmax(pairwise opposition) or MMPO elects the candidate whose greatest opposition from another candidate is minimal. Pairwise wins or losses are not considered; all that matters is the number of votes for one candidate over another.

Pairwise opposition is defined for a pair of candidates. For X and Y, X's pairwise opposition in that pair is the number of ballots ranking Y over X. MMPO elects the candidate whose greatest pairwise opposition is the least.

Minmax(pairwise opposition) does not strictly satisfy the Condorcet criterion or Smith criterion. It also fails the Plurality criterion, and is more indecisive than the other Minmax methods (unless it's used with a tiebreaking rule such as the simple one described below). However, it satisfies the Later-no-harm criterion, the Favorite Betrayal criterion, and in the three-candidate case, the Participation criterion, and the Chicken Dilemma Criterion.

MMPO's choice rule can be regarded as a kind of social optimization: The election of the candidate to whom fewest people prefer another. That choice rule can be offered as a standard in and of itself.

MMPO's simple tiebreaker:

If two or more candidates have the same greatest pairwise opposition, then elect the one that has the lowest next-greatest pairwise opposition. Repeat as needed. 

=cut

no warnings 'experimental';

use Vote::Count::TextTableTiny qw/generate_markdown_table/;
use List::Util qw( min max );
use Carp;
use Try::Tiny;
use Data::Dumper;

sub _scoreminmax ( $self, $method ) {
  my $scores = {};
  my @choices = sort ( keys $self->Active()->%* );
  for my $Choice (@choices) {
    my @ChoiceLoss = ();
  LOOPMMMO: for my $Opponent (@choices) {
      next LOOPMMMO if $Opponent eq $Choice;
      my $M = $self->{'Matrix'}{$Choice}{$Opponent};
      my $S = undef;
      if ( $method eq 'opposition' ) {
        $S = $M->{$Opponent};
      }
      elsif ( $M->{'winner'} eq $Opponent ) {
        $S = $M->{$Opponent} if $method eq 'winning';
        $S = $M->{$Opponent} - $M->{$Choice} if $method eq 'margin';
      }
      else {
        $S = 0;
      }
      $scores->{$Choice}{$Opponent} = $S;
      # there was a bug where sometimes @ChoiceLoss was sorted
      # alphanumerically. resolution force the sort to be numeric.
      push @ChoiceLoss, ( $S );
    }  # LOOPMMMO:
    $scores->{$Choice}{score}
      = [ reverse sort { $a <=> $b } @ChoiceLoss ];
  }
  return $scores;
}

sub _pairmatrixtable1 ( $I, $scores ) {
  my @rows = ( [qw/Choice Choice Votes Opponent Votes Score/] );
  my @choices = sort ( keys $I->Active()->%* );
  for my $Choice (@choices) {
    push @rows, [$Choice];
    for my $Opponent (@choices) {
      my $Cstr = $Choice;
      my $Ostr = $Opponent;
      next if $Opponent eq $Choice;
      my $CVote = $I->{'Matrix'}{$Choice}{$Opponent}{$Choice};
      my $OVote = $I->{'Matrix'}{$Choice}{$Opponent}{$Opponent};
      if ( $I->{'Matrix'}{$Choice}{$Opponent}{'winner'} eq $Choice ) {
        $Cstr = "**$Cstr**";
      }
      if ( $I->{'Matrix'}{$Choice}{$Opponent}{'winner'} eq $Opponent ) {
        $Ostr = "**$Ostr**";
      }
      my $Score = $scores->{$Choice}{$Opponent};
      push @rows, [ ' ', $Cstr, $CVote, $Ostr, $OVote, $Score ];
    }
  }
  return generate_markdown_table( rows => \@rows );
}

sub _pairmatrixtable2 ( $I, $scores ) {
  my @rows = ( [qw/Choice Scores/] );
  my @choices = sort ( keys $I->Active()->%* );
  for my $Choice (@choices) {
    my $scores = join ', ', ( $scores->{$Choice}{'score'}->@* );
    push @rows, [ $Choice, $scores ];
  }
  return generate_markdown_table( rows => \@rows );
}

sub MinMaxPairingVotesTable ( $I, $scores ) {
  my $table1 = $I->_pairmatrixtable1($scores);
  my $table2 = $I->_pairmatrixtable2($scores);
  return "\n$table1\n\n$table2\n";
}

# Matrix will verbose log the setup for regular Condorcet.
# The output is still left in the debug log.
sub _clearVerboselog( $I ) { $I->{'LogV'} = '' }

sub MinMax ( $self, $method ) {
  my $score = $self->_scoreminmax($method);
  my @active = $self->GetActiveList();
  $self->_clearVerboselog();
  $self->logt( "MinMax $method Choices: ", join( ', ', @active ) );
  $self->logv( $self->MinMaxPairingVotesTable($score) );
  my $winner = '';
  my @tied  = ();
  my $round = 0;
  # round inited to 0. The 7th round is 6. round increments at 
  # end of the loop. this sets correct number of rounds.
  my $roundlimit = scalar(@active) -1;
  LOOPMINMAX: while ( $round < $roundlimit ) {
    # start with $bestscore larger than any possible score
    my $bestscore = $self->VotesCast() + 1;
    my @hasbest  = ();
    for my $a (@active) {
      my $this = $score->{$a}{'score'}[$round];
      if ( $this == $bestscore ) { push @hasbest, $a }
      elsif ( $this < $bestscore ) {
        $bestscore = $this;
        @hasbest  = ($a);
      }
    }
    if ( scalar(@hasbest) == 1 ) {
      $winner = shift @hasbest;
      $self->logt("Winner is $winner.");
      return { 'tie' => 0, 'winner' => $winner };
    }
    # only choices that are tied continue to tie breaking.
    @active = @hasbest;
    # if this is the last round @tied must be set.
    @tied = @hasbest;
    if( $bestscore == 0 ) {
      $self->logt(
        "Tie between @tied. Best Score is 0. No more Tiebreakers available." );
      last LOOPMINMAX;
    }
    $round++;
    $self->logt(
      "Tie between @tied. Best Score is $bestscore. Going to Tiebreaker Round $round."
    );
  }
  $self->logt( "Tied: " . join( ', ', @tied ) );
  return { 'tie' => 1, 'tied' => \@tied, 'winner' => 0 };
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
