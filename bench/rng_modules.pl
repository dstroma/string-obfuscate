#!perl
use v5.40;
use Benchmark qw(cmpthese);

cmpthese(100, {
  load_mt => sub { eval "use Math::Random::MT"; },
  load_is => sub { eval "use Math::Random::ISAAC"; },
});

cmpthese(10_000, {
  mt => sub { my $rng = Math::Random::MT->new(123);    $rng->rand() for 1..1000; },
  is => sub { my $rng = Math::Random::ISAAC->new(123); $rng->rand() for 1..1000; },
});

