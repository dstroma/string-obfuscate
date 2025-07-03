#!perl
use v5.36;
use Test::More;

# Require test
require_ok('String::Obfuscate::Base64');
my $obj    = String::Obfuscate::Base64->new(seed => 123);
my $encstr = $obj->obfuscate(q{Polly wanna cracker? \t\n Hello! ~!@#$%^&*()_+`-=[]\;',./':"<>?});
my $decstr = $obj->deobfuscate($encstr);

say $encstr;
say $decstr;

say '-' x 80;

my $obj    = String::Obfuscate::UrlBase64->new(seed => 123);
my $encstr = $obj->obfuscate(q{Polly wanna cracker? \t\n Hello! ~!@#$%^&*()_+`-=[]\;',./':"<>?});
my $decstr = $obj->deobfuscate($encstr);

say $encstr;
say $decstr;
