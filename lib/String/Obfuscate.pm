use v5.40;
package String::Obfuscate {
  use List::Util qw(shuffle);

  my $std_chars = ['a'..'z', 'A'..'Z', 0..9];

  sub new ($class, %params) {
    my $seed  = delete $params{'seed'};
    my $chars = delete $params{'chars'};

    die "unexpected param: $_"
      for keys %params;
    die 'chars must be arrayref of characters'
      if $chars and (not ref $chars or ref $chars ne 'ARRAY');

    $seed  //= srand;
    $chars //= $std_chars;

    my $self = bless { seed => $seed, chars => $chars }, $class;
    $self->obfuscation_sub;
    return $self;
  }

  sub obfuscation_sub ($self) {
    unless ($self->{'sub'}) {
      # Make array of shuffled chars
      srand($self->seed);
      my @chars = List::Util::shuffle($self->{'chars'}->@*);
      srand; # Reseed to not affect outside code relying on rand()

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

  sub obfuscate ($self, $string) {
    return $self->obfuscation_sub->($string);
  }
  *deobfuscate = \&obfuscate;

  sub seed ($self, @newval) {
    $self->{'seed'} = shift(@newval) if @newval > 0;
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
ASCII or base64 encoded strings.

=head1 RATIONALE

It's a fun module but can also be used to obfuscate non-security-sensitive
data in a way that is about 1,000 times faster than encrypting it. This can
be used with an HMAC to verify authenticity, but no mechanism is built in to
do so.

