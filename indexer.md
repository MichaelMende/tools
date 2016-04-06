# NAME

`indexer.pl` HTTP-Crawler and Indexer for ElasticSearch storage

# SYNOPSIS

    perl indexer.pl \
     --http_server fqdn|IP \
     --http_port port \
     --http_sitemap_path path_to_sitemap \
     --http_host fqdn \
     --es_server fqdn|IP \
     --es_port port \
     --es_index index-name \
     --es_logfile log_file_name

## EXAMPLE

    perl indexer.pl \
     --http_server localhost \
     --http_port 8080 \
     --http_host wiki.example.lan \
     --http_sitemap_path /sitemap \
     --es_server localhost \
     --es_port 9200 \
     --es_index wiki_example_lan \
     --es_logfile ./indexer.log

# DESCRIPTION

A HTTP Crawler that indexes websites created with
[pandoc](http://www.pandoc.org/) or any other that provides both
`index.plain` and `index.yaml` files that contain the expected
information.

- Loads a Google style sitemap from given URL
- Fetches for each `index.html` listed in sitemap the correspondent
`index.plain` and `index.yaml` files
- Indexes the `index.plain` and `index.yaml` files with URL of `index.html`
in [ElasticSearch](https://www.elastic.co/)

# ARGUMENTS

- `--http_server`

    Fully Qualified Domain Name (FQDN) or IP of HTTP(S) server. Default: \`localhost\`

- `--http_port`

    Port of HTTP(S) server. Default: \`8080\`

- `--http_host`

    HTTP host name as used in HTTP header \`Host:\`. Default: value from `--http_server`

- `--http_sitemap_path`

    Absolute path to sitemap in Request-URI. Default:\`/sitemap\`

- `--es_server`

    Fully Qualified Domain Name (FQDN) or IP of ElasticSearch server. Default: \`localhost\`

- `--es_port`

    Port of ElasticSearch server. Default: \`9200\`

- `--es_index`

    ElasticSearch index to be used. No default value, mandatory.

- `--es_logfile`

    Path to log file. All ElasticSearch queries are logged here. Default: \`./indexer.log\`

# ElasticSearch schema

- `content`

    Content on `index.plain` file.

- `url`

    URL as found in `<loc>`-tag in sitemap.

- `author`

    Author as found in `index.yaml` file.

- `keywords`

    Keywords as found in `index.yaml` file.

- `abstract`

    Abstract as found in `index.yaml` file.

- `date`

    Date as found in `index.yaml` file.

- `title`

    Title as found in `index.yaml` file.

# AUTHOR

Michael Mende <http://wiki.failover.de>

# COPYRIGHT

This script is released under the same license as Perl.
