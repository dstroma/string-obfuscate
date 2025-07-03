use v5.36;
package String::Obfuscate::Base64 {
  use parent 'String::Obfuscate';
  use constant B64_CHARS => ['a'..'z', 'A'..'Z', 0..9, '+', '/'];
  use MIME::Base64;

  sub new ($class, %params) {
    die 'Do not specify a custom character list in Base64 mode'
      if exists $params{'chars'};

    $params{'chars'} = B64_CHARS;
    $class->SUPER::new(%params);
  }

  sub obfuscate ($self, $string) {
    $self->SUPER::obfuscate(encode_base64($string));
  }

  sub deobfuscate ($self, $string) {
    decode_base64($self->SUPER::deobfuscate($string));
  }
}

1;
