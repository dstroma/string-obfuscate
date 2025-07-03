use v5.36;
package String::Obfuscate::Base64::URL {
  use parent 'String::Obfuscate::Base64';
  sub obfuscate ($self, $string) {
    $string = $self->SUPER::obfuscate($string);
    $string =~ tr`+/=\n`-_`d; # + to - and / to _ and delete newline and =
    $string;
  }
  sub deobfuscate ($self, $string) {
    $string =~ tr`-_`+/`;
    $string .= '=' while length($string) % 4;
    $self->SUPER::deobfuscate($string);
  }
}

1;
