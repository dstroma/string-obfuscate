use v5.36;
package String::Obfuscate::Base64 {
  use parent 'String::Obfuscate';
  use constant B64_CHARS => ['a'..'z', 'A'..'Z', 0..9, '+', '/'];
  use MIME::Base64;

  sub new ($class, %params) {
    $params{'chars'} = B64_CHARS;
    $class->SUPER::new(%params);
  }

  sub obfuscate ($self, $string, %params) {
    $string = encode_base64($string);
    $self->SUPER::obfuscate($string, %params);
  }

  sub deobfuscate ($self, $string, %params) {
    $string = $self->SUPER::deobfuscate($string, %params);
    decode_base64($string);
  }
}

package String::Obfuscate::Base64_Url {
  use parent 'String::Obfuscate::Base64';
  sub obfuscate ($self, $string, %params) {
    $string = $self->SUPER::obfuscate($string, %params);
    $string =~ tr`+/=\n`-_`d; # + to -, / to _, delete newline and =
    return $string;
  }
  sub deobfuscate ($self, $string, %params) {
    $string =~ tr`-_`+/`;
    return $self->SUPER::deobfuscate($string, %params);
  }
}

1;
