package App::CpanTestReport::Controller::Test;
use Mojo::Base 'Mojolicious::Controller';

sub report {
  my $self = shift;

  return $self->_get_report_p($self->stash('guid'))->then(sub {
    my $res = shift;
    $self->respond_to(json => {json => $res}, any => $res);
  });
}

sub _clean {
  local $_ = shift;
  s!^\W+!!;
  s!\W+$!!;
  return $_;
}

sub _get_report_p {
  my ($self, $guid) = @_;
  return $self->backend(cpantesters => [report => $guid])->then(sub { $self->_parse_report(shift) });
}

sub _parse_report {
  my ($self, $report) = @_;
  my @lines = split /\n\r?/, $report->{result}{output}{uncategorized} || '';
  my $section = 'preamble';
  my $sub_section;

  while (defined(my $line = shift @lines)) {
    if ($line =~ /^Sections of this report/) {
      $report->{result}{output}{$section} ||= _clean($report->{block});
      $report->{block} = '';
      $section = 'toc';
    }
    elsif ($line =~ /^-----+$/ and $lines[1] eq $line) {
      $report->{result}{output}{$section} ||= _clean($report->{block});
      $report->{block} = '';
      local $_ = shift @lines;
      next unless /(\w.*)/;
      $section = lc $1;
      $section =~ s!\s+!_!g;
    }
    elsif ($section eq 'prerequisites') {
      $sub_section = $1 if $line =~ /^(\w+):/;
      $report->{result}{output}{$section}{$sub_section}{$1} = $2
        if $sub_section and $line =~ m!(\S+)\s+([\d\.]+)\s+([\d\.]+)!;
    }
    else {
      $report->{block} .= "$line\n";
    }
  }

  $report->{result}{output}{tester_comments} =~ s!Additional comments from \S+!!;
  $report->{result}{output}{$section} = _clean($report->{block});    # Capture last block
  delete $report->{block};
  delete $report->{result}{output}{uncategorized};
  return $report;
}

1;

=encoding utf8

=head1 NAME

App::CpanTestReport::Controller::Test - Test actions

=head1 METHODS

=head2 report

Will show a given test report.

=head1 SEE ALSO

L<App::CpanTestReport>.

=cut
