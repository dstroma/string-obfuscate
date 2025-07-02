use v5.36;
package String::Obfuscate {
  use List::Util ();
  use Module::Loaded qw(is_loaded);
  use constant STD_CHARS => ['a'..'z', 'A'..'Z', 0..9];
  use constant MAX_SEED  => 4_294_967_295;

  our @RNG_CLASSES = qw(
    Math::Random::MT
    Math::Random::ISAAC::XS
    Math::Random::ISAAC::PP
  );

  # Maybe a class is already loaded?
  my @loaded_rng_classes = grep { is_loaded($_) } @RNG_CLASSES;

  sub new ($class, %params) {
    my $seed  = delete $params{'seed'};  # optional seed
    my $chars = delete $params{'chars'}; # optional arrayref to char list
    my $rng   = delete $params{'rng'};   # force class or object, or pp

    die 'unexpected param(s): ' . join(', ', keys %params)
      if keys %params;
    die 'chars must be a ref to an array of characters'
      if $chars and (not ref $chars or ref $chars ne 'ARRAY');

    # Check if user wants to use a specific object or perl builtin rand()?
    my $rng_obj      = ref $rng ? $rng : undef;
    my $use_perl_rng = (!$rng_obj and $rng and ($rng eq 'perl'));

    # Maybe load external RNG module
    unless ($use_perl_rng or $rng_obj) {
      my @rngs_to_try = $rng ? ($rng) : (@loaded_rng_classes, @RNG_CLASSES);
      foreach my $i (@rngs_to_try) {
        eval {
          eval "require $i" unless is_loaded($i);
          $rng_obj = $i->new(defined $seed ? ($seed) : ());
        };
        last if $rng_obj;
      }
    }

    die "could not utilize rng class or object $rng"
      if $rng and $rng ne 'perl' and not $rng_obj;

    my $self = bless { }, $class;
    $self->{rng}   = $rng_obj if $rng_obj;
    $self->{chars} = $chars || STD_CHARS;
    $self->{seed}  = $seed  // make_seed();
    $self->{code}  = $self->make_obfuscation_sub;
    return $self;
  }

  sub make_obfuscation_sub ($self) {
    srand($self->seed) unless $self->{'rng'};
    local $List::Util::RAND = sub { $self->{'rng'}->rand(@_) } if $self->{'rng'};
    my $from_chars = join '', List::Util::shuffle($self->{'chars'}->@*);
    srand() unless $self->{'rng'}; # Reseed to not affect outside code

    my $to_chars = reverse $from_chars;
    my $sub = eval qq<
      sub (\$string) {
        \$string =~ tr/$from_chars/$to_chars/;
        return \$string;
      };
    > or die $@;
    return $sub;
  }

  sub obfuscate ($self, $string, %params) {
    return ref $self ? $self->{'code'}->($string) : $self->new(%params)->obfuscate($string);
  }
  *deobfuscate = \&obfuscate;

  sub make_seed () { int(rand(MAX_SEED)) }
  sub seed ($self) { $self->{'seed'}     }
}

=head1 NAME

String::Obfuscate - Reversibly obfuscate (scramble) a string.

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    use String::Obfuscate;
    my $obf = String::Obfuscate->new(seed => 123); # optional seed
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

=head1 SPEED AND COMPARISON TO SIMILAR MODULES

This module generates an obfuscate() method for each object based on the RNG
speed and the desired RNG module. Once generated, using it is very fast. To
properly take advantage of its speed, when running in a peristent environment,
create your String::Obfuscate object(s) with the desired seed(s) during the
compile-time phase of your program. You can then use the object(s) to encode
or decode strings several orders of magnitude faster than encrypting them.

Crypt::Cipher::Vigenere is extremely slow and only scrambles letters, not
digits or other characters.

Crypt::CVS is very slow and uses a fixed cipher.

Crypt::Rot47 is very fast, but uses a fixed cipher.

