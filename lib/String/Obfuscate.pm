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
    my $to_chars = quotemeta(join('', _shuffle($rand_fn, $self->{chars}->@*)));

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

  sub _shuffle ($rand_func, @array) {
    if ($List::Util::XS::VERSION) {
      local $List::Util::RAND = $rand_func;
      return List::Util::shuffle(@array);
    } else {
      for (my $idx = scalar @array; $idx > 1;) {
        my $swap_idx      = int($rand_func->() * $idx--);
        my $tmp_val       = $array[$swap_idx];
        $array[$swap_idx] = $array[$idx];
        $array[$idx]      = $tmp_val;
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

String::Obfuscate - Reversibly obfuscate a string with a substitution cipher.


=head1 VERSION

version 0.01


=head1 SYNOPSIS

    use String::Obfuscate;
    my $obf = String::Obfuscate->new(seed => 123);
    $obf->obfuscate('hello'); # 'xn88Y'


=head1 DESCRIPTION

String::Obfuscate implements a substitution type cipher adequate to obfuscate
a string without meaning to be cryptographically secure. The cipher mapping is
dynamically generated based on a seed or seeds which are fed to a random number
generator.

Specify seed(s) yourself to get a predictable result. Otherwise, the order will
be different with each String::Obfuscate object, but obfuscated strings can
still be reversed with the same object, or by asking the object for the seed and
and re-using the same seed.

If no seed is supplied, this module will create one based on the time and PID,
however this method may change in the future.

Random numbers for the List::Util::shuffle function are generated with
Math::Random::ISAAC, which has both XS and pure-perl implementations. This
has several advantages:
 - The XS module is very fast while the PP module can be used as a fallback
 - Using a discrete RNG prevents alterating the state of perl's built-in RNG
 - The algorithm can be implemented in another language if desired

If, for whatever reason, List::Util::XS is not available, a pure-perl
implementation of the same shuffle algorithm will be used (not List::Util::PP
which uses a different shuffle algorithm). Again, this ensures reproducibility.
It also means you can read the perl source of this module to learn how to
re-implement the correct shuffle algorithm rather than reading the XS/C code.

Only ASCII letters and numbers are scrambled, but you can specify your own
character set to the new constructor with the chars param, which takes a
reference to an array of characters, not a string. This is done to prevent
excessive string copying and for a possible future feature where a plain string
might have a special meaning, such as the name of a character set.

Included in this distribution are String::Obfuscate::Base64 and
String::Obfuscate::Base64::URL which will convert the string to base 64 using
the standard or URL encoding, respectively, then obfuscate it. These subclasses
do not let you specify a character set. If the string you desire to obfuscate
contains binary data or UTF-8 characters, it is recommended you use one of
the Base64 subclasses. However, although it is not the intended purpose, this
module could be used with binary input and output like so:

    my $obj = String::Obfuscate->new(chars => [map { chr($_) } 0..255]);

At object creation, this module generates the cipher code using a translation
(tr) regex, giving it a fast runtime for persistent environments.


=head1 REQUIREMENTS

    Math::Random::ISAAC (::XS or ::PP)

    perl v5.36 or greater

A minimum perl version of 5.36 is required as this module uses subroutine
signatures. As of this writing, this version is more than three years old.
You are encouraged to upgrade.


=head1 RATIONALE

This module can also be used to obscure non-security-sensitive data in a way
that is several orders of magnitude faster than encrypting it, while at the
same time, using a more complex cipher than one with a fixed rotation (such
as Crypt::Cipher::Rot47, which is only slightly faster than this module).


=head1 CONSTRUCTOR

=over 4

=item B<new PARAMS>

Returns a new L<String::Obfuscate> object constructed according to PARAMS,
where PARAMS are name/value pairs. All PARAMS are optional. If a seed is not
specified, one will be created.

    $ob = String::Obfuscate->new;
    $ob = String::Obfuscate->new(seed => 123);
    $ob = String::Obfuscate->new(chars => ['a'..'f',0..9]);

=item chars

The characters used to generate the cipher, specified as an arrayref.

=item seed

The seed or seed(s). May be specified as a number or an arrayref of multiple
seeds. The random number generator can take up to 255 seeds.

=back


=head1 OBJECT METHODS

=over4

=item B<seed()>

Returns the seed. Regardless of how the seed was originally supplied, this
method will always return an arrayref.

Note the seed is set at object creation and cannot be changed later.

=item B<obfuscate($string)>

Returns the obfuscated version of $string without altering the original.

=item B<deobfuscate($string)>

Returns the deobfuscated version of $string without altering the original.

=back


=head1 AUTHOR

Dondi Michael Stroma (dstroma@gmail.com)


=head1 COPYRIGHT

Copyright (C) 2025 by Dondi Michael Stroma. All rights reserved.


=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
