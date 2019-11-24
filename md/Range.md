# Range (Score) Voting Overview

Range or Score Voting is a variant of Ranked Choice Voting.

* There are a fixed number of Rankings available, usually 5, 10 or 100.

* Voters (Typically) May Rank Choices Equally.

* Voters Rank their best choice highest, the inverse of Ranked Choice.

Range Voting is usually resolved by Borda Count directly using the ratings assigned by the voters, by fixing the number of available rankings it resolves Borda Count's weighting problem. Condorcet can resolve Range Voting, but the ability to rank choices equally increases the possibility of ties. When resolving by IRV it is necessary to split the vote for equally ranked choices.

# Reading Range Ballots

See [Vote::Count::ReadBallots](https://metacpan.org/pod/Vote::Count::ReadBallots)

# Range Methods

## Score

Score is a method provided by [Vote::Count::Borda](https://metacpan.org/pod/Vote::Count::Borda) that will score the ballots based on the scores provided by the voters.

## STAR (Score Then Automatic Runoff)

Creates a runoff between the top 2 choices. Implemented in [Vote::Count::Method::STAR](https://metacpan.org/pod/Vote::Count::Method::STAR).

## Condorcet

[Vote::Count::Matrix](https://metacpan.org/pod/Vote::Count::Method::Matrix) supports Range Ballots.

## IRV

Not yet implemented.

## Tie Breakers

Only Approval currently supports Range Ballots.

# Ordinal Ranged

Limiting voters to one choice per Rank has the advantage of creating a ballot which translates perfectly to Ranked Choice ballots. From an analysis standpoint have such versatile ballots is valuable. While IRV and Condorcet work with Range Ballots, they work better with Ordinal Ballots, where Borda works much better with Range ballots. As alternate ballots gain popularity the ability to compare the results accross methods with the same live data will be valuable.

Unfortunately limiting the number of choices is also limiting the voter's expression. The larger the Range is the less this issue matters. On a Range 100 ballot it is unlikely that in a real world situation a voter is going to be able to or want to rank nearly that many. Because the Range needs space to express strong and weak preference 10 is probably the minimum size at which imposing Ordinality would be reasonable.