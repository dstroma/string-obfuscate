#!perl
use v5.36;
use Benchmark qw(cmpthese);

use String::Obfuscate;
use Crypt::Cipher::Vigenere;
use Crypt::CVS;
use Crypt::Rot47;
use Crypt::CBC;


my @strings = (
 'abcdefg',
 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ',
 '0123456789abcdef'x128
);

warn "CVS........" . Crypt::CVS::scramble('abcdef');
warn "Vig........" . Crypt::Cipher::Vigenere->new('abcdef')->encode('abcdefABCDEF12345');
warn "Rot47......" . Crypt::Rot47->new->encrypt('abcdef 1234');

sub cbc ($str) {
  state $cipher = Crypt::CBC->new(-pass => 'my secret password', -cipher => 'Cipher::AES', -nodeprecate=>1);
  $cipher->decrypt($cipher->encrypt($str));
}

sub rot47 ($str) {
  state $cipher = Crypt::Rot47->new;
  $cipher->decrypt($cipher->encrypt($str));
}

sub cvs ($str) {
  Crypt::CVS::descramble(Crypt::CVS::scramble($str));
}

sub vig ($str) {
  state $vig = Crypt::Cipher::Vigenere->new('hellothere');
  my $enc = $vig->encode($str);
  $vig->reset;
  my $dec = $vig->decode($enc);
  $dec;
}

sub obs ($str) {
  state $obs = String::Obfuscate->new(rng => 'perl', seed => time());
  $obs->deobfuscate($obs->obfuscate($str));
}

sub obs_mt ($str) {
  state $obs = String::Obfuscate->new(rng => 'Math::Random::MT', seed => time());
  $obs->deobfuscate($obs->obfuscate($str));
}

sub obs_ixs ($str) {
  state $obs = String::Obfuscate->new(rng => 'Math::Random::ISAAC::XS', seed => time());
  $obs->deobfuscate($obs->obfuscate($str));
}

sub obs_ipp ($str) {
  state $obs = String::Obfuscate->new(rng => 'Math::Random::ISAAC::PP', seed => time());
  $obs->deobfuscate($obs->obfuscate($str));
}

if (my $test = 1) {
  say "Rot47:";
  say substr($_, 0, 32) . " == " . substr(rot47($_), 0, 32) for @strings;
  say "Vig:";
  say substr($_, 0, 32) . " == " . substr(vig($_), 0, 32)   for @strings;
  say "CVS:";
  say substr($_, 0, 32) . " == " . substr(cvs($_), 0, 32)   for @strings;
  say "String::Obfuscate:";
  say substr($_, 0, 32) . " == " . substr(obs($_), 0, 32)   for @strings;
}


#my $obf = String::Obfuscate->new(seed => 0.1234, use_Math_Random_MT => 0);

cmpthese(10_000, {
  cbc     => sub { cbc($_)     for @strings },
  cvs     => sub { cvs($_)     for @strings },
  vig     => sub { vig($_)     for @strings },
  rot47   => sub { rot47   ($_) for @strings },
  obs     => sub { obs     ($_) for @strings },
  obs_mt  => sub { obs_mt  ($_) for @strings },
  obs_ixs => sub { obs_ixs ($_) for @strings },
  obs_ipp => sub { obs_ipp ($_) for @strings },
});
