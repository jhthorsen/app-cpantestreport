package App::CpanTestReport;
use Mojo::Base 'Mojolicious';

our $VERSION = '0.01';

sub startup {
  my $self = shift;

  $self->plugin('PromiseActions');

  my $r = $self->routes;
  $r->get('/')->to('root#search')->name('search');
  $r->get('/author/:id')->to('author#summary')->name('author.summary');
  $r->get('/dist/*name')->to('dist#report')->name('dist.report');
}

1;
