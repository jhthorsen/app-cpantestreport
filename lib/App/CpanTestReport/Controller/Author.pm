package App::CpanTestReport::Controller::Author;
use Mojo::Base 'Mojolicious::Controller';

use List::Util 'sum';

sub summary {
  my $self = shift->render_later;

  return $self->_get_summary_by_author_p($self->stash('id'))->then(sub {
    my $res = shift;
    $self->param(q => $self->stash('id'));
    $self->respond_to(json => {json => $res}, any => {page => 'author', %$res});
  });
}

sub _get_summary_by_author_p {
  my ($self, $author) = @_;

  my @metacpan = (
    metacpan => [qw(release _search)],
    [fields => 'distribution,version', size => '100', q => sprintf('author:%s AND status:latest', uc $author)],
  );

  my %latest;
  return $self->backend(@metacpan)->then(sub {
    my $hits = shift;
    $hits = $hits->{hits} while ref $hits eq 'HASH' and $hits->{hits};
    $latest{$_->{fields}{distribution}} = $_->{fields}{version} for @$hits;

    return $self->backend(cpantesters => [release => author => uc $author]);
  })->then(sub {
    my $json = shift;
    my (@dists, %stats);

    for my $r (sort { $b->{fail} <=> $a->{fail} || $a->{dist} cmp $b->{dist} } @$json) {
      next unless $latest{$r->{dist}} and $r->{version} eq $latest{$r->{dist}};
      $r->{name} = delete $r->{dist};
      $stats{$_} += $r->{$_} || 0 for qw(fail na pass unknown);
      push @dists, $r;
    }

    return {dists => \@dists, stats => \%stats};
  });
}

1;

=encoding utf8

=head1 NAME

App::CpanTestReport::Controller::Author - Author actions

=head1 METHODS

=head2 summary

Show summary for an author.

=head1 SEE ALSO

L<App::CpanTestReport>

=cut
