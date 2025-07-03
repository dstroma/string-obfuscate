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
1;

package String::Obfuscate::UrlBase64 {
  use parent 'String::Obfuscate';
  use constant UB64_CHARS => ['a'..'z', 'A'..'Z', 0..9, '-', '_'];
  use MIME::Base64::URLSafe;

  sub new ($class, %params) {
    $params{'chars'} = UB64_CHARS;
    $class->SUPER::new(%params);
  }

  sub obfuscate ($self, $string, %params) {
    $string = urlsafe_b64encode($string);
    $self->SUPER::obfuscate($string, %params);
  }

  sub deobfuscate ($self, $string, %params) {
    $string = $self->SUPER::deobfuscate($string, %params);
    urlsafe_b64decode($string);
  }
}
1;
