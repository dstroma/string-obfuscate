use v5.36;
package String::Obfuscate {
  use List::Util ();
  use Math::Random::ISAAC ();
  use constant STD_CHARS => ['a'..'z', 'A'..'Z', 0..9];
  use constant MAX_SEED  => 2**32;

  sub new ($class, %params) {
    my $seed  = delete $params{'seed'};  # optional seed
    my $chars = delete $params{'chars'}; # optional arrayref to char list

    die 'unexpected param(s): ' . join(', ', keys %params)
      if keys %params;
    die 'chars must be a ref to an array of characters'
      if $chars and (not ref $chars or ref $chars ne 'ARRAY');
    die 'chars cannot contain backtick (`) or hyphen (-)'
      if $chars and (join('', @$chars) =~ m/[-`]/);

    my $self = bless { }, $class;
    $self->{chars} = $chars || STD_CHARS;
    $self->{seed}  = $seed  // time();
    $self->{rng}   = Math::Random::ISAAC->new($self->{seed});
    $self->{code}  = $self->make_obfuscation_sub;
    return $self;
  }

  sub make_obfuscation_sub ($self) {
    my $rng = $self->{rng};
    local $List::Util::RAND = sub { $rng->rand() };

    my $from_chars = join('', List::Util::shuffle($self->{chars}->@*));
    my $to_chars   = scalar(reverse($from_chars));

    my $sub = eval qq<
      sub (\$string) {
        \$string =~ tr`$from_chars`$to_chars`;
        return \$string;
      };
    > or die $@;

    return $sub;
  }

  sub obfuscate ($self, $string, %params) {
    return ref $self ? $self->{'code'}->($string) : $self->new(%params)->obfuscate($string);
  }
  *deobfuscate = \&obfuscate;

  sub seed ($self) { $self->{'seed'} }
}

=head1 NAME

String::Obfuscate - Reversibly obfuscate (scramble) a string.

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    use String::Obfuscate;
    my $obf = String::Obfuscate->new(seed => 123); # optional seed for rand()
    $obf->obfuscate('abc'); # 'cba'

=head1 DESCRIPTION

String::Obfuscate scrambles a string in a reversible way. Specify a seed for
perl's srand() function to get a predictable result. Otherwise, the order
will be different with each String::Obfuscate object, but scrambled strings
can still be reversed with the same object, or by asking the object for the
seed used and re-using the same seed.

Only ASCII letters and numbers are scrambled, making this module suitable for
ASCII or base64 encoded strings. You can specify your own character set
to the new constructor with the chars param, which takes a reference to an
array of characters.

=head1 CAVEATS

This module will mess with perl's randon number generator seed, although it
will be re-seeded with a new random seed afterward. If you do not want this,
you should install one of the following supported external RNG modules:

    Math::Random::MT
    Math::Random::ISAAC  # ::XS or ::PP

=head1 RATIONALE

This module can also be used to obfuscate non-security-sensitive data in a way
that is about 1,000 times faster than encrypting it. This can be used with an
HMAC to verify authenticity, but no mechanism is built in to do so.

=head1 CONSTRUCTOR

All parameters are optional. If a seed is not specified, perl's srand()
function will be called to seed the random number generator and obtain
a seed.

    $ob = String::Obfuscate->new;
    $ob = String::Obfuscate->new(seed => 123);
    $ob = String::Obfuscate->new(chars => ['a'..'f',0..9]);

=head1 OPTIONAL MODULES

    Math::Random::MT
    Math::Random::ISAAC  # ::XS or ::PP
    Class::Unload        # for tests
