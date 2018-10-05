package App::CpanTestReport;
use Mojo::Base 'Mojolicious';

use Mojo::Redis;
use Scalar::Util 'blessed';
use Time::Piece;
use Time::Seconds;

our $VERSION = '0.01';

sub startup {
  my $self = shift;

  $self->defaults(
    backends => {cpantesters => 'http://api.cpantesters.org/v3', metacpan => 'https://fastapi.metacpan.org/v1'},
    error    => ''
  );

  $self->hook(around_action => \&_hook_around_action);
  $self->_add_helper_backend;
  $self->_add_helper_cache;
  $self->_add_helper_human_date;

  my $r = $self->routes;
  $r->get('/')->to('root#search', page => 'search')->name('search');
  $r->get('/search')->to('root#search', page => 'search');
  $r->get('/author/:id')->to('author#summary', page => 'author')->name('author.summary');
  $r->get('/dist/*name')->to('dist#report',    page => 'dist')->name('dist.report');
  $r->get('/report/:guid')->to('test#report', page => 'report')->name('test.report');
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
        $url->clone->scheme(undef)->to_string,
        $c->stash('cache_timeout') || 600,
        sub {
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
      return $c->stash->{'redis.cache'}
        ||= $redis->cache(namespace => 'cpantestreport')->refresh($c->param('_refresh'));
    }
  );
}

sub _add_helper_human_date {
  my $self = shift;

  $self->helper(
    'human.date' => sub {
      my $date = Mojo::Date->new(pop);
      my $now  = time;

      return localtime($date->epoch)->strftime($date->epoch < $now - ONE_DAY * 180 ? '%e. %b %Y' : '%e. %b, %H:%M');
    }
  );
}

sub _hook_around_action {
  my ($next, $c) = @_;
  my @args = $next->();

  $c->inactivity_timeout(20);

  if (blessed($args[0]) and $args[0]->can('then')) {
    my $tx = $c->render_later->tx;
    $args[0]->then(
      undef,
      sub {
        my $err = shift;
        my $reply_with = $err =~ /Not Found/i ? 'not_found' : 'exception';
        $c->reply->$reply_with($err);
        undef $tx;
      }
    );
    $args[0]->wait if $args[0]->can('wait');
  }

  return @args;
}

1;

=encoding utf8

=head1 NAME

App::CpanTestReport - Search for CPAN Testers reports by module, distribution or author.

=head1 SYNOPSIS

  $ ./script/cpantestreport daemon --listen http://*:3000

=head1 DESCRIPTION

L<App::CpanTestReport> is a web page where you can search for CPAN Testers
reports by module, distribution or author and see test reports created by
L<http://cpantesters.org/>.

=head1 RESOURCES

=over 2

=item * /

Show a search page.

=item * /search

Alias for "/".

=item * /search?q=JHTHORSEN

=item * /search?author=JHTHORSEN

Redirects to author search results.

=item * /search?dist=Mojolicious

=item * /search?dist=Mojolicious-8.01

=item * /search?q=Mojolicious

=item * /search?q=Mojolicious-8.01

Redirects to dist search results.

=item * /author/JHTHORSEN

Show a summary of all the dists for a given author.

=item * /dist/Mojolicious

Redirects to the latest version of L<Mojolicious>

=item * /dist/Mojolicious-8.01

Show search results for L<Mojolicious> version 8.01.

=item * /report/57fffae2-689f-1015-8f24-a8e65f496936

Show a given test report.

=back

=head1 METHODS

=head2 startup

Called by L<Mojolicious> to start up the web server.

=head1 AUTHOR

Jan Henning Thorsen

=head1 COPYRIGHT AND LICENSE

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<http://api.cpantesters.org/>,
L<https://api.metacpan.org/> and
L<https://github.com/cpan-testers/cpantesters-web>.

=cut
