use strict;
use warnings;
use 5.022;

package Vote::Count::Common;
use Moose::Role;

use feature qw /postderef signatures/;
no warnings 'experimental';

use Storable 3.15 'dclone';

# ABSTRACT: Role shared by Count and Matrix for common functionality. See Vote::Count Documentation.

our $VERSION='1.07';

=head1 NAME

Vote::Count::Common

=head1 VERSION 1.07

=head1 Synopsis

This Role is consumed by Vote::Count and Vote::Count::Matrix. It provides common methods for the Active Set.

=cut

has 'Active' => (
  is      => 'ro',
  isa     => 'HashRef',
  lazy    => 1,
  builder => '_defaultactive',
);

sub _defaultactive ( $self ) { return dclone $self->BallotSet()->{'choices'} }

sub SetActive ( $self, $active ) {
  # Force deref
  $self->{'Active'} = dclone $active;
  # if there is a child PairMatrix, update it too.
  if ( defined $self->{'PairMatrix'}) { 
    $self->{'PairMatrix'}{'Active'} = $self->{'Active'} 
  }
}

sub ResetActive ( $self ) { 
  $self->{'Active'} = $self->_defaultactive();
}

# I was typing the equivalent too often. made a method.
sub SetActiveFromArrayRef ( $self, $active ) {
  $self->SetActive( { map { $_ => 1 } $active->@* } );
}

sub GetActive ( $self ) {
  # Force deref
  my $active = $self->Active();
  return dclone $active;
}

# this deref also happens a lot
sub GetActiveList( $self ) {
  return( sort( keys( $self->Active->%* ) ) );
}


sub VotesCast ( $self ) {
  return $self->BallotSet()->{'votescast'};
}

sub VotesActive ( $self ) {
  unless ( $self->BallotSet()->{'options'}{'rcv'} ) {
    die "VotesActive Method only supports rcv"
  }
  my $set         = $self->BallotSet();
  my $active      = $self->Active();
  my $activeCount = 0;
LOOPVOTESACTIVE:
    for my $B ( values $set->{ballots}->%* ) {
        for my $V ( $B->{'votes'}->@* ) {
            if ( defined $active->{$V} ) {
                $activeCount += $B->{'count'};
                next LOOPVOTESACTIVE;
            }
        }
    }
  return $activeCount;
}

sub BallotSetType ( $self ) {
  if ( $self->BallotSet()->{'options'}{'rcv'} ) {
    return 'rcv';
  }
  elsif ( $self->BallotSet()->{'options'}{'range'} ) {
    return 'range';
  }
  else {
    die "BallotSetType is undefined or unknown type.";
  }
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
