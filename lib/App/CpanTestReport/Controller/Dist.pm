package App::CpanTestReport::Controller::Dist;
use Mojo::Base 'Mojolicious::Controller';

my $VERSION_RE = qr{[\d\.]++};

sub report {
  my $self = shift;
  my $name = $self->stash('name');

  if ($name =~ m!-$VERSION_RE$!) {
    die 'TODO';
  }
  else {
    return $self->_get_latest_dist_p($name)->then(sub {
      return $self->reply->not_found unless my $dist = shift;
      return $self->redirect_to($self->url_for('dist.report', {format => $self->stash('format'), name => $dist}));
    });
  }
}

sub _get_latest_dist_p {
  my ($self, $module) = @_;

  $module =~ s!-!::!g;    # Turn Dist-Name into Module::Name
  return $self->backend(metacpan => [module => $module])->then(sub {
    my $module = shift;
    return undef unless $module->{distribution} and $module->{version} and $module->{version} =~ /$VERSION_RE$/;
    return join '-', @$module{qw(distribution version)};
  });
}

1;
