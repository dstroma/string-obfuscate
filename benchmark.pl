use v5.40;
use String::Obfuscate;
use Benchmark qw(cmpthese);

my @strings = (qw(
  abc
  abcdefghijklmnopqrstuvwxyz0123456789
  abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789
  abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789
));

use Crypt::CBC;
my $cipher = Crypt::CBC->new(
  -pass => 'alsifjawefiOW4EIWwfksf943083948308sfWIJFE',
  -cipher => 'Cipher::AES',
  -pbkdf => 'pbkdf2'
);

say String::Obfuscate->obfuscate($_, seed => 12345, use_Math_Random_MT => 0) for @strings;
say '';
say String::Obfuscate->obfuscate($_, seed => 12345, use_Math_Random_MT => 1) for @strings;
say '';
say $cipher->encrypt($_) for @strings;
say '';

my $int_obf = String::Obfuscate->new(seed => 54321, use_Math_Random_MT => 0);
my $ext_obf = String::Obfuscate->new(seed => 54321, use_Math_Random_MT => 1);

say 'Beginning benchmark';
cmpthese(1_000_000, {
  #internal => sub { String::Obfuscate->obfuscate($_, seed => 12345, use_Math_Random_MT => 0) for @strings },
  #external => sub { String::Obfuscate->obfuscate($_, seed => 12345, use_Math_Random_MT => 1) for @strings },

  internaloo => sub { $int_obf->obfuscate($_) for @strings },
  externaloo => sub { $ext_obf->obfuscate($_) for @strings },

  #encrypt  => sub { $cipher->encrypt($_) for @strings },
});
