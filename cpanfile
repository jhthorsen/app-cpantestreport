# You can install this project with curl -L http://cpanmin.us | perl - https://github.com/jhthorsen/app-cpantestreport/archive/master.tar.gz
requires "Mojo::Redis"                         => "3.11";
requires "Mojolicious"                         => "8.00";
requires "Mojolicious::Plugin::PromiseActions" => "0.07";
requires "Text::Markdown"                      => "1.00";

test_requires "Test::More" => "0.88";
