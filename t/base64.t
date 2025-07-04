#!perl
use v5.36;
use Test::More;

# Require test
require_ok('String::Obfuscate::Base64');

my $str    = qq{Polly wanna cracker? \t\n Hello! ~!@#$%^&*()_+`-=[]\;',./':"<>?};
{
    my $obj    = String::Obfuscate::Base64->new(seed => 12345);
    my $encstr = $obj->obfuscate($str);
    my $decstr = $obj->deobfuscate($encstr);
    is($decstr => $str, 'Base64 - decoded string matches original');
}

{
    my $obj    = String::Obfuscate::Base64_URL->new(seed => 12345);
    my $encstr = $obj->obfuscate($str);
    my $decstr = $obj->deobfuscate($encstr);
    is($decstr => $str, 'Base64_URL - decoded string matches original');
}

done_testing();
