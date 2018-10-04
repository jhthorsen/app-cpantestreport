package App::CpanTestReport::Controller::Root;
use Mojo::Base 'Mojolicious::Controller';

use Mojo::Util 'trim';

sub search {
  my $self  = shift;
  my $query = $self->_normalize_search_query;
  my %attrs = (format => $self->stash('format'));

  if ($query->{author}) {
    return $self->redirect_to('author.summary', %attrs, id => $query->{author});
  }
  elsif ($query->{dist} and $query->{version}) {
    return $self->redirect_to('dist.report', %attrs, name => join '-', @$query{qw(dist version)});
  }
  elsif ($query->{dist}) {
    return $self->redirect_to('dist.report', %attrs, name => $query->{dist});
  }

  my @examples = (
    $self->url_for('/search.json')->query([q      => 'Mojolicious'])->to_abs,
    $self->url_for('/search.json')->query([q      => 'Mojolicious 8.01'])->to_abs,
    $self->url_for('/search.json')->query([q      => 'Mojolicious-8.01'])->to_abs,
    $self->url_for('/search.json')->query([q      => 'JHTHORSEN'])->to_abs,
    $self->url_for('/search.json')->query([author => 'JHTHORSEN'])->to_abs,
    $self->url_for('/search.json')->query([dist   => 'Mojolicious'])->to_abs,
    $self->url_for('/search.json')->query([dist   => 'Mojolicious', version => '8.01'])->to_abs,
    $self->url_for('author.summary', %attrs, id   => 'JHTHORSEN')->to_abs,
    $self->url_for('dist.report',    %attrs, name => 'Mojolicious-8.01')->to_abs,
    $self->url_for('dist.report',    %attrs, name => 'Mojolicious-8.01')
      ->query([osname => 'linux', grade => 'unknown', grade => 'na', platform => 'x86_64', perl => '5.6', perl => '5.24'
      ])->to_abs,
  );

  $self->respond_to(json => {json => {examples => \@examples}}, any => {examples => \@examples});
}

sub _normalize_search_query {
  my $c     = shift;
  my $query = $c->req->url->query->to_hash;

  for my $p (grep {/\w/} map { trim $_ } split /\s+/, delete $query->{q} // '') {
    if ($p =~ /^(.+)-([\d\.]+)/) {
      $query->{dist}    ||= $1;
      $query->{version} ||= $2;
    }
    if ($p =~ /^\d/) {
      $query->{version} ||= $p;
    }
    elsif ($p =~ /^[A-Z]+$/) {
      $query->{author} ||= $p;
    }
    else {
      $query->{dist} ||= $p;
      $query->{dist} =~ s!::!-!;
    }
  }

  return $query;
}

1;
