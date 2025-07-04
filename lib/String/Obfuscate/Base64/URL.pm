use v5.36;
package String::Obfuscate::Base64::URL {
  use parent 'String::Obfuscate::Base64';

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
