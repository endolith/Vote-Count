#!/usr/bin/env perl

use 5.022;

# Using Test2, important to specify which version of Test2
# since later versions may break things.
use Test2::V0;
use Test2::Bundle::More;
use Test::Exception;
use Data::Dumper;
# use JSON::MaybeXS;
# use YAML::XS;
use feature qw /postderef signatures/;

use Path::Tiny;

use Vote::Count::Method::CondorcetDropping;
use Vote::Count::Method::MinMax;
use Vote::Count::ReadBallots 'read_ballots';

my $tennessee = Vote::Count::Method::MinMax->new(
    'BallotSet' => read_ballots('t/data/tennessee.txt') );
my $loop1 =  Vote::Count::Method::MinMax->new(
    'BallotSet' => read_ballots('t/data/loop1.txt') );

subtest '_scoreminmax winning' => sub {

  # note( Dumper $loop1->_scoreminmax( 'winning' ) );
  my $A = $tennessee->_scoreminmax( 'winning' );
  my $L = $loop1->_scoreminmax( 'winning' );
  is_deeply( $A->{'NASHVILLE'}{'Score'}, [ 0, 0, 0 ], 
  'TN Nashville didnt lose @score is [ 0, 0, 0 ]');
  is_deeply( $A->{'KNOXVILLE'}{'Score'}, [ 83, 68, 0 ], 
  'TN Knoxville  @score is [ 83, 68, 0 ]');
  for my $othertn ( qw/NASHVILLE KNOXVILLE CHATTANOOGA/) {
    is( $A->{'MEMPHIS'}{$othertn}, 58,
    "TN all other choices scored 58 vs Memphis, check $othertn");
  }
  my $xmintchip = {
    'ROCKYROAD'=> 0,
    'Score' => [ 9, 0, 0, 0, 0, 0, 0 ],
    'CARAMEL'=> 0,
    'STRAWBERRY' => 0,
    'CHOCOLATE'=> 9,
    'RUMRAISIN'=> 0,
    'VANILLA'=> 0,
    'PISTACHIO'=> 0
    };
  my $xchocolate = {
    'ROCKYROAD'=> 0,
    'Score' => [ 9, 0, 0, 0, 0, 0, 0 ],
    'CARAMEL'=> 0,
    'STRAWBERRY' => 0,
    'MINTCHIP'=> 0,
    'RUMRAISIN'=> 0,
    'VANILLA'=> 9,
    'PISTACHIO'=> 0
    };
  is_deeply( $L->{'MINTCHIP'}, $xmintchip, 
    'loop1 Mintchip 1 loss at 9.');
  is_deeply( $L->{'CHOCOLATE'}, $xchocolate, 
    'loop1 Chocolate also 1 loss at 9.');  
}; # '_scoreminmax winning'

subtest '_scoreminmax margin' => sub {

  my $A = $tennessee->_scoreminmax( 'margin' );
  # note( Dumper $A );
  my $L = $loop1->_scoreminmax( 'margin' );
  is_deeply( $A->{'NASHVILLE'}{'Score'}, [ 0, 0, 0 ], 
  'TN Nashville didnt lose @score is [ 0, 0, 0 ]');
  is_deeply( $A->{'KNOXVILLE'}{'Score'}, [ 66, 36, 0 ], 
  'TN Knoxville  @score is [  66, 36, 0 ]');
  for my $othertn ( qw/NASHVILLE KNOXVILLE CHATTANOOGA/) {
    is( $A->{'MEMPHIS'}{$othertn}, 16,
    "TN all other choices scored 16 vs Memphis, check $othertn");
  }
  my $xmintchip = {
    'ROCKYROAD'=> 0,
    'Score' => [ 2, 0, 0, 0, 0, 0, 0 ],
    'CARAMEL'=> 0,
    'STRAWBERRY' => 0,
    'CHOCOLATE'=> 2,
    'RUMRAISIN'=> 0,
    'VANILLA'=> 0,
    'PISTACHIO'=> 0
    };
  my $xchocolate = {
    'ROCKYROAD'=> 0,
    'Score' => [ 5, 0, 0, 0, 0, 0, 0 ],
    'CARAMEL'=> 0,
    'STRAWBERRY' => 0,
    'MINTCHIP'=> 0,
    'RUMRAISIN'=> 0,
    'VANILLA'=> 5,
    'PISTACHIO'=> 0
    };
  is_deeply( $L->{'MINTCHIP'}, $xmintchip, 
    'loop1 Mintchip 1 loss at 2.');
  is_deeply( $L->{'CHOCOLATE'}, $xchocolate, 
    'loop1 this time Chocolate 1 loss at 5.');  
  ok 1;
}; # '_scoreminmax margin'

# note( $loop1->PairingVotesTable() );

# subtest 'Approval Dropping' => sub {

#   note "********** LOOPSET *********";
#   my $LoopSet = Vote::Count::Method::CondorcetDropping->new(
#     'BallotSet' => read_ballots('t/data/loop1.txt'),
#     'DropStyle' => 'all',
#     'DropRule'  => 'approval',
#   );
#   my $rLoopSet = $LoopSet->RunCondorcetDropping();
#   is( $rLoopSet->{'winner'}, 'VANILLA', 'loopset approval all winner' );
#   note $LoopSet->logd();
# };

done_testing();