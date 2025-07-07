use v5.36;
package String::Obfuscate {
  use Math::Random::ISAAC ();
  use constant STD_CHARS => ['a'..'z', 'A'..'Z', 0..9];
  eval { require List::Util::XS };

  sub new ($class, %params) {
    my $seed  = delete $params{'seed'};  # optional seed
    my $chars = delete $params{'chars'}; # optional arrayref to char list

    die 'unexpected param(s): ' . join(', ', keys %params)
      if keys %params;
    die 'chars must be a ref to an array of characters'
      if $chars and (not ref $chars or ref $chars ne 'ARRAY');

    $seed = make_seed() if !defined $seed;
    $seed = [$seed]     if !ref $seed;

    my $self = bless {
      chars => $chars || STD_CHARS,
      seed  => $seed
    }, $class;

    $self->make_codec;
  }

  sub make_codec ($self) {
    my $rng      = Math::Random::ISAAC->new($self->seed->@*);
    my $rand_fn  = sub { $rng->rand() };
    my $fr_chars = quotemeta(join('', $self->{chars}->@*));
    my $to_chars = quotemeta(join('', my_shuffle($rand_fn, $self->{chars}->@*)));

    $self->{encoder} = eval qq<
      sub (\$string) {
        \$string =~ tr|$fr_chars|$to_chars|;
        return \$string;
      };
    > or die $@;

    $self->{decoder} = eval qq<
      sub (\$string) {
        \$string =~ tr|$to_chars|$fr_chars|;
        return \$string;
      };
    > or die $@;

    return $self;
  }

  sub my_shuffle ($rand_func, @array) {
    if ($List::Util::XS::VERSION) {
      local $List::Util::RAND = $rand_func;
      return List::Util::shuffle(@array);
    } else {
      for (my $idx = scalar @array; $idx > 1;) {
        my $swap = int($rand_func->() * $idx--);
        my $tmp = $array[$swap];
        $array[$swap] = $array[$idx];
        $array[$idx]  = $tmp;
      }
      return @array;
    }
  }

  sub make_seed   ()               { [time(), $$]    }
  sub seed        ($self)          { $self->{'seed'} }
  sub obfuscate   ($self, $string) { $self->{encoder}->($string) }
  sub deobfuscate ($self, $string) { $self->{decoder}->($string) }
}

1;

=head1 NAME

String::Obfuscate - Reversibly obfuscate (scramble) a string.

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    use String::Obfuscate;
    my $obf = String::Obfuscate->new(seed => 123);
    $obf->obfuscate('abc'); # 'cba'

=head1 DESCRIPTION

String::Obfuscate "scrambles" a string in a reversible way using a substitution
type cipher. Specify a seed for a predictable result. Otherwise, the order
will be different with each String::Obfuscate object, but scrambled strings
can still be reversed with the same object, or by asking the object for the
seed used and re-using the same seed.

Only ASCII letters and numbers are scrambled, but you can specify your own
character set to the new constructor with the chars param, which takes a
reference to an array of characters (not a string).

Included in this distribution are String::Obfuscate::Base64 and
String::Obfuscate::Base64::URL which will convert the string to base 64 using
the standard or URL encoding, respectively, then obfuscate it. These subclasses
do not let you specify a character set.

=head1 REQUIRED MODULES

    Math::Random::ISAAC (::XS or ::PP)

=head1 RATIONALE

This module can also be used to obfuscate non-security-sensitive data in a way
that is several orders of magnitude faster than encrypting it. This can be used
with an HMAC to verify authenticity, but no mechanism is built in to do so.

=head1 CONSTRUCTOR

All parameters are optional. If a seed is not specified, one will be created.

    $ob = String::Obfuscate->new;
    $ob = String::Obfuscate->new(seed => 123);
    $ob = String::Obfuscate->new(chars => ['a'..'f',0..9]);
