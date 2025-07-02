#!perl
use v5.36;
use Benchmark qw(cmpthese);

use Math::Random::MT;
use Math::Random::ISAAC::PP;
use Math::Random::ISAAC::XS;
use Class::Unload;

sub doit ($class) {
  my $ob = $class->new(rand());
  $ob->rand for 0..500;
}

sub doit2 ($class) {
  Class::Unload->unload($class);
  eval "require $class";
}


cmpthese(50_000, {
  mt  => sub { doit2('Math::Random::MT') },
  ixs => sub { doit2('Math::Random::ISAAC::XS') },
  ipp => sub { doit2('Math::Random::ISAAC::PP') },
});

__END__

=pod

Result:

# Test 1: 1 object creation + 25 random numbers:

            Rate   ipp    mt   ixs
    ipp   3782/s    --  -96%  -98%
    mt   92593/s 2348%    --  -56%
    ixs 208333/s 5408%  125%    --

Math::Random::ISAAC::XS is very fast. Math::Random::MT is about half the speed
even though it's an XS module. Math::Random::ISAAC::PP is slow, but is pure-
perl and uses the same algorithm as the XS module therefore they are compatible
and will produce the same random numbers with the same seed.

# Test 2: 1 object creation + 1 random number per object

            Rate    ipp     mt    ixs
    ipp   4094/s     --   -99%   -99%
    mt  297619/s  7170%     --   -49%
    ixs 581395/s 14102%    95%     --

# Test 3: 1 object creation + 500 random numbers

          Rate   ipp    mt   ixs
    ipp  1385/s    --  -80%  -92%
    mt   6868/s  396%    --  -61%
    ixs 17730/s 1180%  158%    --

# Test 4: Module load and unload only

          Rate  ipp   mt  ixs
    ipp 1731/s   -- -20% -62%
    mt  2169/s  25%   -- -52%
    ixs 4550/s 163% 110%   --
