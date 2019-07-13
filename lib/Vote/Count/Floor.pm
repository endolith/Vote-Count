use strict;
use warnings;
use 5.022;
use feature qw /postderef signatures/;

package Vote::Count::Floor;
use namespace::autoclean;
use Moose::Role;

use Data::Printer;

no warnings 'experimental';

# load the roles providing the underlying ops.
with  'Vote::Count::Approval',
      'Vote::Count::TopCount',
      ;

sub _FloorMin( $self, $floorpct ) {
  my $pct = $floorpct > .2 ? $floorpct / 100 : $floorpct;
  my $min = int( $self->CountBallots() * $pct );
  return int( $self->CountBallots() * $pct );
}

sub _DoFloor( $self, $ranked, $cutoff ) {
  my @active = ();
  my @remove = ();
  for my $s ( keys $ranked->%* ) {
    if ( $ranked->{$s} >= $cutoff) { push @active, $s }
    else {
      push @remove, $s;
      $self->logv(
        "Removing: $s: $ranked->{$s}, minimum is $cutoff."
      );
    }
  }
  $self->logt(
    "Floor Rule Eliminated: ",
    join( ', ', @remove ),
    "Remaining: ",
    join( ', ', @active ),
    );
  return { map { $_ => 1 } @active };
}

sub ApprovalFloor( $self, $floorpct=5 ) {
  $self->logt( "Applying Floor Rule of $floorpct\% Approval Count.");
  return $self->_DoFloor(
    $self->Approval()->RawCount(),
    $self->_FloorMin($floorpct )
  );
}

sub TopCountFloor( $self, $floorpct=5 ) {
  $self->logt( "Applying Floor Rule of $floorpct\% First Choice Votes.");
  return $self->_DoFloor(
    $self->TopCount()->RawCount(),
    $self->_FloorMin($floorpct )
  );
}

sub TCA( $self ) {
  $self->logt( 'Applying Floor Rule: Approval Must be at least ',
    '50% of the Most First Choice votes for any Choice.');
  my $tc = $self->TopCount();
  # arraytop returns a list in case of tie.
  my $winner = shift( $tc->ArrayTop->@* );
  my $tcraw = $tc->RawCount()->{$winner};
  my $cutoff = int( $tcraw /2 );
  $self->logv(
    "The most first choice votes for any choice is $tcraw.",
    "Cutoff will be $cutoff");
  my $ac = $self->Approval()->RawCount();
  return $self->_DoFloor(
    $self->Approval()->RawCount(),
    $cutoff );
}


1;

=pod

