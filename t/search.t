use Mojo::Base -strict;
use Test::Mojo;
use Test::More;

my $t = Test::Mojo->new('App::CpanTestReport');

for my $path (qw(/ /search)) {
  $t->get_ok("$path")->status_is(200)->element_exists('form[action="/"]')
    ->element_exists('form input[type="search"][name="q"]')->element_exists('button.btn')
    ->element_exists('a[href="https://github.com/jhthorsen/app-cpantestreport#readme"]');

  $t->get_ok("$path?q=Mojolicious")->status_is(302)->header_is(Location => '/dist/Mojolicious');

  $t->get_ok("$path?q=JSON::Validator")->status_is(302)->header_is(Location => '/dist/JSON-Validator');

  $t->get_ok("$path?q=%20App::git::ship%20%201.00%20%20")->status_is(302)
    ->header_is(Location => '/dist/App-git-ship-1.00');

  $t->get_ok("$path?q=App-git-ship")->status_is(302)->header_is(Location => '/dist/App-git-ship');

  $t->get_ok("$path?q=App-git-ship%200.01")->status_is(302)->header_is(Location => '/dist/App-git-ship-0.01');

  $t->get_ok("$path?q=JHTHORSEN")->status_is(302)->header_is(Location => '/author/JHTHORSEN');
}

done_testing;
