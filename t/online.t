use Mojo::Base -strict;
use Mojo::File 'path';
use Test::Mojo;
use Test::More;

$ENV{MOJO_REDIS_CACHE_OFFLINE} = 1;
$ENV{MOJO_USERAGENT_CACHE_DIR} = path(qw(t cache));

plan skip_all => 'Cache directory was not found' unless -d $ENV{MOJO_USERAGENT_CACHE_DIR};
plan skip_all => $@ unless 'require Mojo::UserAgent::Role::Cache;1';

my $t = Test::Mojo->new('App::CpanTestReport');

$t->get_ok('/author/JHTHORSEN')->status_is(200)->text_is('h1', 'Summary for "JHTHORSEN"')
  ->element_exists('form[action="/"] input[name="q"]')->element_count_is('.badge', 5)
  ->element_exists('.badge.text-dark[data-badge="48"]')->element_exists('.badge.text-error[data-badge="107"]')
  ->element_exists('.badge.text-success[data-badge="24066"]')->element_exists('.badge.text-warning[data-badge="197"]')
  ->element_exists('.badge.text-primary[data-badge="1"]')->element_exists('a[href="/dist/JSON-Validator-2.19"]');

$t->get_ok('/dist/JSON-Validator')->status_is(302)->header_is('Location', '/dist/JSON-Validator-2.19');

$t->get_ok('/dist/JSON-Validator-2.19')->status_is(200)->text_is('h1', 'JSON-Validator-2.19')
  ->element_count_is('.badge', 15)->element_exists('.badge.text-dark[data-badge="581"]')
  ->element_exists('.badge.text-error[data-badge="10"]')->element_exists('.badge.text-success[data-badge="571"]')
  ->element_exists('a[href="/report/08430fa1-6bf4-1014-9862-baaa5d7f190a"]');

$t->get_ok('/report/08430fa1-6bf4-1014-9862-baaa5d7f190a')->status_is(200)->text_like('h1', qr{JSON-Validator 2\.19})
  ->text_is('h1 .text-error', 'Fail')->element_exists('a[href="mailto:root@chorny.net"]')
  ->text_is('h2', 'Program output')->text_like('pre.program-output', qr{Failed test})
  ->element_exists('ul.requires li a[href="/dist/Mojolicious-7.28"]')
  ->element_exists('ul.build-requires li a[href="/dist/Test-More-1.30"]')
  ->element_exists('ul.configure-requires li a[href="/dist/ExtUtils-MakeMaker"]');

done_testing;
