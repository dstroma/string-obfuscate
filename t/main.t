use v5.40;
use Test::More;

# Require
require_ok('String::Obfuscate');

# New with no options
{
  my $obj = String::Obfuscate->new;
  ok(ref $obj, 'new object');

  # Get auto seed
  ok($obj->seed, 'new object has seed');
  ok($obj->seed =~ m/^\d+$/, 'seed is a number');

  # Obfuscate and deobfiscate a string
  my $str = 'abcdefg'; #say $str;
  my $obf_str = $obj->obfuscate($str); #say $obf_str;
  ok($obf_str, 'obfuscated string is true');
  ok($obf_str ne $str, 'obfuscated string is not original');
  ok($obj->deobfuscate($obf_str) eq $str, 'obfuscated string can be reversed');
}

# Canned seed
{
  my $seed = 12345;
  my $in   = 'abcdefgABCDEFG12345';
  my $out  = 'unvQDAFfSGelgC3z1yT';
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

done_testing();
