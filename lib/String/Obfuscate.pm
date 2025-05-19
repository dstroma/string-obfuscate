use v5.40;
package String::Obfuscate {
  use List::Util qw(shuffle);
  use constant STD_CHARS => ['a'..'z', 'A'..'Z', 0..9];

  # Maybe use Math::Random::MT
  our $use_Math_Random_MT = undef; # undef=optional, 0=never, true=force
  our $loaded_Math_Random_MT;
  {
    eval {
      require Math::Random::MT;
      $loaded_Math_Random_MT = 1;
    } if !defined $use_Math_Random_MT or $use_Math_Random_MT;

    die "Cannot load Math::Random::MT"
      if $use_Math_Random_MT and not $loaded_Math_Random_MT;
  }

  sub new ($class, %params) {
    my $seed     = delete $params{'seed'};
    my $chars    = delete $params{'chars'};
    my $use_MRMT = delete $params{'use_Math_Random_MT'} // $use_Math_Random_MT;

    die "unexpected param: $_"
      for keys %params;
    die 'chars must be arrayref of characters'
      if $chars and (not ref $chars or ref $chars ne 'ARRAY');

    $use_MRMT = Math::Random::MT->new(
      defined $seed ? ($seed) : ()
    ) if $use_MRMT or (!defined $use_MRMT and $loaded_Math_Random_MT);

    $chars //= STD_CHARS;
    $seed  //= $use_MRMT ? $use_MRMT->get_seed() : srand;

    my $self = bless { seed => $seed, chars => $chars, MRMT => $use_MRMT }, $class;
    $self->obfuscation_sub;
    return $self;
  }

  sub obfuscation_sub ($self) {
    unless ($self->{'sub'}) {
      # Make array of shuffled chars
      my @chars; # = @{ $self->{'chars'} ? $self->{'chars'} : STD_CHARS };
      if ($self->{'MRMT'}) {
        local $List::Util::RAND = sub { $self->{'MRMT'}->rand(@_) };
        @chars = List::Util::shuffle($self->{'chars'}->@*);
      } else {
        srand($self->seed);
        @chars = List::Util::shuffle($self->{'chars'}->@*);
        srand; # Reseed to not affect outside code relying on rand()
      }

      my $from = join '', @chars;
      my $to   = reverse $from;
      my $sub  = eval qq<
        sub (\$string) {
          \$string =~ tr/$from/$to/;
          return \$string;
        };
      > or die $@;
      $self->{'sub'} = $sub;
    }
    return $self->{'sub'};
  }

  sub obfuscate ($self, $string, %params) {
    return ref $self ? $self->obfuscation_sub->($string) : $self->new(%params)->obfuscate($string);
  }
  *deobfuscate = \&obfuscate;

  sub seed ($self) {
    return $self->{'seed'};
  }
}

__END__

=head1 NAME

String::Obfuscate - Reversibly scramble a string.

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    use String::Obfuscate;
    my $obf = String::Obfuscate->new(seed => 123); # optional seed for rand()
    $obf->obfuscate('abc'); # 'cba'

    # Optionally get a reference to the seed-specific obfuscation sub
    my $code = $obf->obfuscation_sub;
    $code->('abc'); # 'cba'

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
you should install the optional Math::Random::MT and it will use that instead.

=head1 RATIONALE

It's a fun module but can also be used to obfuscate non-security-sensitive
data in a way that is about 1,000 times faster than encrypting it. This can
be used with an HMAC to verify authenticity, but no mechanism is built in to
do so.

=head1 CONSTRUCTOR

All parameters are optional. If a seed is not specified, perl's srand()
function will be called to seed the random number generator and obtain
a seed.

    $ob = String::Obfuscate->new;
    $ob = String::Obfuscate->new(seed => 123);
    $ob = String::Obfuscate->new(chars => ['a'..'f',0..9]);

