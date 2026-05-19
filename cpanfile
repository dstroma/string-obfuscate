requires perl => '5.20.0';

requires 'MIME::Base64';
requires 'Math::Random::ISAAC';

on test => sub {
  requires 'Test::More' => '0.98';
};

