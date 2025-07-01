#!perl
use v5.36;
use Test::More;
use Module::Loaded ();
our @rng_classes = qw(Dummy Math::Random::MT Math::Random::ISAAC::XS Math::Random::ISAAC::PP);

# Require test
require_ok('String::Obfuscate');

# Loop through RNG modules
foreach my $i (undef, @rng_classes) {
  warn "$i module not available, skipping" && next
    if $i and not eval "require $i; 1";

  # If we pre-load an RNG module, String::Obfuscate should use that one
  # This test is optional and only performed if Class::Unload is available
  if ($i and $i ne 'Dummy' and eval "require Class::Unload; 1") {
    Class::Unload->unload($_) for (@rng_classes, 'String::Obfuscate');
    eval "require $i" or die $@;
    eval "require String::Obfuscate" or die $@;
    # use Data::Dumper; warn Dumper { INC => [ sort keys %INC ] };
    my $obj = String::Obfuscate->new();
    my $rng_type = ref $obj->{rng};
    ok($rng_type eq $i, "Used preloaded RNG module $i (got $rng_type)");
  }

  # Call new() with specific RNG module or perl
  {
    # Check new() successfully returns object
    my $obj = String::Obfuscate->new(rng => $i || 'perl');
    ok(ref $obj, 'new object');

    # Check object uses the requested RNG module
    if ($i) {
      ok(ref $obj->{rng} eq $i, 'The requested RNG module is correct -- ' . $i);
    } else {
      ok(not($obj->{rng}), 'Using perl builtin rand');
    }

    # Get auto seed
    ok($obj->seed, 'new object has seed');
    ok($obj->seed =~ m/^\d+$/, 'seed is a number');

    # Obfuscate and deobfuscate a string
    my $str = 'abcdefg'; #say $str;
    my $obf_str = $obj->obfuscate($str); #say $obf_str;
    ok($obf_str, 'obfuscated string is true');
    ok($obf_str ne $str, 'obfuscated string is not original');
    ok($obj->deobfuscate($obf_str) eq $str, 'obfuscated string can be reversed');
  }

  # Canned seed
  {
    my $seed = 123456;
    my $in   = 'abcdefgABCDEFG12345';
    my $out  = String::Obfuscate->obfuscate($in, seed => $seed);
    warn $out;
    my $obj = String::Obfuscate->new(seed => $seed);
    ok(ref $obj, 'create object with specified seed');

    # Get seed
    ok($obj->seed == $seed, 'seed is equal to given seed');

    # Obfuscate and deobfiscate a string
    ok($obj->obfuscate($in), 'canned seed obfuscate');
    ok($obj->obfuscate($in) eq $out, 'canned seed obfuscated string is expected string');
    ok($obj->deobfuscate($out) eq $in, 'canned seed obfuscated string is reversed');
  }

  # Custom charset
  {
    my $obj = String::Obfuscate->new(chars => ['a'..'f']);
    ok($obj->obfuscate('zxy123') eq 'zxy123', 'characters not in charset not scrambled'); # say $obj->obfuscate('zxy123');
    ok($obj->obfuscate('abcdef') ne 'abcdef', 'characters in charset are scrambled');
  }

  # Class method interface
  {
    ok(String::Obfuscate->obfuscate('abc') ne 'abc', 'obfuscate using class method');
    ok(
      String::Obfuscate->deobfuscate(
        String::Obfuscate->obfuscate('abc123ABC', seed => 3141529),
        seed => 3141529
      ) eq 'abc123ABC', 'obfuscate and reverse obfuscate using class method with specified seed'
    );
  }
}

done_testing();
