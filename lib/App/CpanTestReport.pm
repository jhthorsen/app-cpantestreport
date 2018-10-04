package App::CpanTestReport;
use Mojo::Base 'Mojolicious';

use Mojo::Redis;

our $VERSION = '0.01';

sub startup {
  my $self = shift;

  $self->defaults(
    backends => {cpantesters => 'http://api.cpantesters.org/v3', metacpan => 'https://fastapi.metacpan.org/v1'},
    error    => ''
  );

  $self->plugin('PromiseActions');

  $self->_add_helper_backend;
  $self->_add_helper_cache;

  my $r = $self->routes;
  $r->get('/')->to('root#search')->name('search');
  $r->get('/author/:id')->to('author#summary')->name('author.summary');
  $r->get('/dist/*name')->to('dist#report')->name('dist.report');
}

sub _add_helper_backend {
  my $self = shift;

  $self->helper(
    backend => sub {
      my ($c, $backend, $path, $query) = @_;

      my $url = Mojo::URL->new($c->stash->{backends}{$backend});
      push @{$url->path}, @$path;
      $url->query($query) if $query;

      return $c->cache->compute_p(
        "cpan_testers:$backend:$url" => $c->stash('cache_timeout') || 600 => sub {
          return $c->app->ua->get_p($url)->then(sub {
            my $tx = shift;
            return $tx->res->json unless my $err = $tx->error;
            die "[$backend] $err->{message} <<< $url";
          });
        }
      );
    }
  );
}

sub _add_helper_cache {
  my $self  = shift;
  my $redis = Mojo::Redis->new;

  $self->helper(
    cache => sub {
      my $c = shift;
      return $c->stash->{'redis.cache'} ||= $redis->cache->refresh($c->param('_refresh'));
    }
  );
}

1;
