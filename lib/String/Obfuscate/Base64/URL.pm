use v5.36;
package String::Obfuscate::Base64::URL {
  use parent 'String::Obfuscate::Base64';

  # While MIME::Base64 does have a URL mode, it is pure-perl
  # so might as well to do it ourselves and avoid re-implementing
  # the base64 conversion

  sub obfuscate ($self, $str) {
    $str = $self->SUPER::obfuscate($str);
    $str =~ tr`+/=\n`-_`d; # + to - and / to _ and delete newline and =
    $str;
  }

  sub deobfuscate ($self, $str) {
    $str =~ tr`-_`+/`;
    $str .= '=' while length($str) % 4;
    $self->SUPER::deobfuscate($str);
  }
}

1;
