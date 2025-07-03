#!perl
use v5.36;
use Test::More;

# Require test
require_ok('String::Obfuscate::Base64');
my $str    = qq{Polly wanna cracker? \t\n Hello! ~!@#$%^&*()_+`-=[]\;',./':"<>?};
{
    my $obj    = String::Obfuscate::Base64->new(seed => 1234);
    my $encstr = $obj->obfuscate($str);
    my $decstr = $obj->deobfuscate($encstr);
    say $encstr;
    say $decstr;
    ok($str eq $decstr, 'Decoded string matches original');
}

say '-' x 80;

{
    my $obj    = String::Obfuscate::Base64_Url->new(seed => 1234);
    my $encstr = $obj->obfuscate($str);
    my $decstr = $obj->deobfuscate($encstr);
    say "ENCODED: $encstr";
    say "DECODED: $decstr";
    ok($str eq $decstr, 'Decoded string matches original');
}

done_testing();
