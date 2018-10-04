package App::CpanTestReport::Controller::Dist;
use Mojo::Base 'Mojolicious::Controller';

my $VERSION_RE = qr{[\d\.]+};

sub report {
  my $self = shift;

  my ($name, $version, $format) = $self->stash('name') =~ m!^(.+)-($VERSION_RE)(?:\.(html|json))?$!;
  ($name, $format) = $self->stash('name') =~ m!^(.+)(?:\.(html|json))?$! unless $name;
  $self->stash(format => $format) if $format;

  if (!$name) {
    return $self->reply->not_found;
  }
  elsif ($name and $version) {
    $self->param(q => "$name-$version");
    return $self->_get_report_p({name => $name, version => $version}, $self->req->url->query->to_hash)->then(sub {
      my $res = shift;
      $self->respond_to(json => {json => $res}, any => $res);
    });
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

sub _get_report_p {
  my ($self, $args, $filters) = @_;

  return $self->backend(cpantesters => [summary => @$args{qw(name version)}])->then(sub {
    my $reports = shift;

    if (ref $reports ne 'ARRAY' or !@$reports) {
      my $error = ref $reports eq 'HASH' ? $reports->{errors}[0]{message} : 'No reports found.';
      $error .= '.' unless $error =~ /[^a-z]$/i;
      return {error => $error, reports => [], stats => {}};
    }

    my (@filtered, %stats);
    for my $report (@$reports) {
      my @perl_v = map { /^\d+$/ ? int : $_ } split /\./, $report->{perl};
      my $perl_m = join '.', @perl_v[0, 1];
      $report->{platform} =~ s!^(?:\w+\.)?(\w+)-.*$!$1!;
      $stats{grade}{$report->{grade}}++;
      $stats{osname}{$report->{osname}}{$report->{grade}}++;
      $stats{perl}{$perl_m}{$report->{grade}}++;
      $stats{platform}{$report->{platform}}{$report->{grade}}++;

      next unless _in($report->{grade},    $filters->{grade});
      next unless _in($report->{osname},   $filters->{osname});
      next unless _in($report->{platform}, $filters->{platform});
      next unless _in($perl_m, $filters->{perl}) or _in($report->{perl}, $filters->{perl});

      delete @$report{qw(dist reporter version)};
      $report->{perl} = \@perl_v;
      push @filtered, $report;
    }

    @filtered = sort {
           $a->{grade} cmp $b->{grade}
        || $a->{osname} cmp $b->{osname}
        || $a->{osvers} cmp $b->{osvers}
        || $b->{perl}[1] <=> $a->{perl}[1]
    } @filtered;

    return {reports => \@filtered, stats => \%stats};
  });
}

sub _in {
  my ($needle, $filter) = (shift // '', shift);
  return 1 unless defined $filter;
  return int grep { $needle eq $_ } ref $filter ? @$filter : ($filter);
}

1;
