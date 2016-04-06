#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use Encode qw(decode_utf8);
use Data::Dumper;
use Pod::Usage;
use Getopt::Long;
use LWP::UserAgent;
use XML::XPath;
use XML::XPath::XMLParser;
use YAML::XS;
use Search::Elasticsearch;

our $opt_http_server = 'localhost';
our $opt_http_port = 80;
our $opt_http_sitemap_path = '/sitemap';
our $opt_http_host;
our $opt_es_server = 'localhost';
our $opt_es_port = 9200;
our $opt_es_index;
our $opt_es_logfile = './indexer.log';

GetOptions (
  "http_server=s",
  "http_port=i",
  "http_sitemap_path=s",
  "http_host=s",
  "es_server=s",
  "es_port=i",
  "es_index=s",
	"es_logfile=s",
) or pod2usage(1);

pod2usage(-msg => 'Missing Option "--es_index index-name"',-exitval => 2,-verbose => 1,-output  => \*STDERR) unless $opt_es_index;
$opt_http_host = $opt_http_server unless $opt_http_host;

# Default Values for indexed files
my $yaml_defaults = {
  'author'   => 'Michael Mende',
  'keywords' => '',
  'abstract' => '',
  'date'     => '1970-01-01',
  'title'    => 'Untitled',
};

my $ua = LWP::UserAgent->new(
  timeout => 5,
);
$ua->default_header( 'Host' => $opt_http_host );

# Fetch sitemap
my $response = $ua->get("http://${opt_http_server}:${opt_http_port}/${opt_http_sitemap_path}");
die Dumper($response) unless $response->is_success;

# Array of <loc> locations
my $xp = XML::XPath->new(xml => $response->content);
my $nodeset = $xp->find('/urlset/url/loc');
my @locations = map {$_->string_value =~ s/^\s+|\s+$//r} $nodeset->get_nodelist;

# Clean up ElasticSearch Index
my $es = Search::Elasticsearch->new( trace_to => ['File',$opt_es_logfile] );
eval { $es->indices->delete( index => $opt_es_index ) };
eval { $es->indices->create( index => $opt_es_index ) };

# foreach @locations 
foreach my $loc (@locations) {

  next unless $loc =~ /\/index\.html?$/;

  ## fetch .plain -> body
  my $plain_r = $ua->get($loc =~ s/html$/plain/r);
  next unless $plain_r->is_success;

  ## fetch .yaml -> author keywords abstract date title
  my $yaml_r = $ua->get($loc =~ s/html$/yaml/r);
  next unless $yaml_r->is_success;

  ## YAML as var
  my $yaml_vals = YAML::XS::LibYAML::Load($yaml_r->content);

  ## push ElasticSearch
  $es->index(
        index => $opt_es_index,
        type  => 'text',
        body  => {
          content => decode_utf8($plain_r->content),
          url     => decode_utf8($loc),
          author  => $yaml_vals->{author}   ? $yaml_vals->{author}   : $yaml_defaults->{author},
          keywords=> $yaml_vals->{keywords} ? $yaml_vals->{keywords} : $yaml_defaults->{keywords},
          abstract=> $yaml_vals->{abstract} ? $yaml_vals->{abstract} : $yaml_defaults->{abstract},
          date    => $yaml_vals->{date}     ? $yaml_vals->{date}     : $yaml_defaults->{date},
          title   => $yaml_vals->{title}    ? $yaml_vals->{title}    : $yaml_defaults->{title},
        }
  );

}

__END__

=pod

=encoding UTF-8

=head1 NAME

C<indexer.pl> HTTP-Crawler and Indexer for ElasticSearch storage

=head1 SYNOPSIS

 perl indexer.pl \
  --http_server fqdn|IP \
  --http_port port \
  --http_sitemap_path path_to_sitemap \
  --http_host fqdn \
  --es_server fqdn|IP \
  --es_port port \
  --es_index index-name \
  --es_logfile log_file_name

=head2 EXAMPLE

 perl indexer.pl \
  --http_server localhost \
  --http_port 8080 \
  --http_host wiki.example.lan \
  --http_sitemap_path /sitemap \
  --es_server localhost \
  --es_port 9200 \
  --es_index wiki_example_lan \
  --es_logfile ./indexer.log

=head1 DESCRIPTION

A HTTP Crawler that indexes websites created with
L<pandoc|http://www.pandoc.org/> or any other that provides both
C<index.plain> and C<index.yaml> files that contain the expected
information.

=over

=item

Loads a Google style sitemap from given URL

=item

Fetches for each C<index.html> listed in sitemap the correspondent
C<index.plain> and C<index.yaml> files

=item

Indexes the C<index.plain> and C<index.yaml> files with URL of C<index.html>
in L<ElasticSearch|https://www.elastic.co/>

=back

=head1 ARGUMENTS

=over

=item C<--http_server>

Fully Qualified Domain Name (FQDN) or IP of HTTP(S) server. Default: `localhost`

=item C<--http_port>

Port of HTTP(S) server. Default: `8080`

=item C<--http_host>

HTTP host name as used in HTTP header `Host:`. Default: value from C<--http_server>

=item C<--http_sitemap_path>

Absolute path to sitemap in Request-URI. Default:`/sitemap`

=item C<--es_server>

Fully Qualified Domain Name (FQDN) or IP of ElasticSearch server. Default: `localhost`

=item C<--es_port>

Port of ElasticSearch server. Default: `9200`

=item C<--es_index>

ElasticSearch index to be used. No default value, mandatory.

=item C<--es_logfile>

Path to log file. All ElasticSearch queries are logged here. Default: `./indexer.log`

=back

=head1 ElasticSearch schema

=over

=item C<content>

Content on C<index.plain> file.

=item C<url>

URL as found in C<E<lt>locE<gt>>-tag in sitemap.

=item C<author>

Author as found in C<index.yaml> file.

=item C<keywords>

Keywords as found in C<index.yaml> file.

=item C<abstract>

Abstract as found in C<index.yaml> file.

=item C<date>

Date as found in C<index.yaml> file.

=item C<title>

Title as found in C<index.yaml> file.

=back

=head1 AUTHOR

Michael Mende <http://wiki.failover.de>

=head1 COPYRIGHT

This script is released under the same license as Perl.

=cut
