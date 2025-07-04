#!perl
use v5.36;
use Test::More;

require_ok('String::Obfuscate');
require_ok('String::Obfuscate::Base64');
require_ok('String::Obfuscate::Base64::URL');

do_test('String::Obfuscate');
do_test('String::Obfuscate::Base64');
do_test('String::Obfuscate::Base64::URL');

done_testing();

# Require test
sub do_test ($class) {
  say "Testing $class...";

  foreach my $str (qw(a ab abc abcd abcde 1 12 123 a! b? c?!)) {
    # Check new() successfully returns object
    my $obj = $class->new();
    is(ref $obj => $class, "new $class object without seed");

    # Get auto seed
    ok($obj->seed, 'new object has seed ' . $obj->seed);
    ok($obj->seed =~ m/^\d+$/, 'seed is a number');

    # Obfuscate and deobfuscate a string
    my $obf_str = $obj->obfuscate($str); #say $obf_str;
    ok($obf_str, 'obfuscated string is true');
    ok($obf_str ne $str, 'obfuscated string is not original');
    ok($obj->deobfuscate($obf_str) eq $str, 'obfuscated string can be reversed');
  }

  # Canned seed
  foreach my $seed (123456, $$, time()) {
    my $in   = 'abcdefgABCDEFG12345';
    my $out  = $class->new(seed => $seed)->obfuscate($in);
    my $obj  = $class->new(seed => $seed);

    ok(ref $obj,                         'create object with specified seed');

    # Get seed
    is($obj->seed              => $seed, 'seed is equal to given seed');

    # Obfuscate and deobfiscate a string
    ok($obj->obfuscate($in),             'specified seed obfuscate');
    is($obj->obfuscate($in)    => $out,  'specified seed obfuscated string is repeatable');
    is($obj->deobfuscate($out) => $in,   'specified seed obfuscated string is reversed');
  }

  # Custom charset
  unless ($class =~ m/Base64/) {
    my $obj = $class->new(chars => ['a'..'f']);
    ok($obj->obfuscate('zxy123') eq 'zxy123', 'characters not in charset not scrambled');
    ok($obj->obfuscate('abcdef') ne 'abcdef', 'characters in charset are scrambled');
  }

  # Crazy characters
  unless ($class =~ m/Base64/) {
    my $ok    = 1;
    my @chars = map { chr($_) } 0..255;
    my $str   = join '', @chars; # q{~!@#$%^&*()_+`1234567890-={}|[]\;',./:"<>?]abcdefg123456};
    for my $i (0..1_000) {
      my $obj = $class->new(seed => $i, chars => \@chars);
      my $enc = $obj->obfuscate($str);
      my $dec = $obj->deobfuscate($enc);
      unless ($dec eq $str) {
        $ok = 0;
        last;
      }
    }
    ok($ok, "nonprintable string and charset test");
  }

  # Class method interface
  # FEATURE REMOVED
  #{
  #  ok($class->obfuscate('abc') ne 'abc', 'obfuscate using class method');
  #  ok(
  #    $class->deobfuscate(
  #      $class->obfuscate('abc123ABC', seed => 3141529),
  #      seed => 3141529
  #    ) eq 'abc123ABC', 'obfuscate and reverse obfuscate using class method with specified seed'
  #  );
  #}

}
