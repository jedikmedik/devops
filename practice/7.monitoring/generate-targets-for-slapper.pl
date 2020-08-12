#!/usr/bin/env perl

use v5.14.2;
use strict;
use warnings;

use HTTP::Tiny;
use Pod::Usage;
use Getopt::Long;

my $url;
my $count = 10_000;
my $pastes_count = 100;
my $invalid_pcnt = 0;
my $max_body_size = 1024;
my $permalink_alternative_url = '';
my $help = 0;

GetOptions(
    'help|?'                        => \$help,
    'url=s'                         => \$url,
    'count=i'                       => \$count,
    'pastes_count=i'                => \$pastes_count,
    'invalid_pcnt=f'                => \$invalid_pcnt,
    'max_body_size=i'               => \$max_body_size,
    'permalink_alternative_url=s'   => \$permalink_alternative_url,
) or die("Error in command line arguments\n");
pod2usage(1) if $help;

if (!$url) {
    die "need url\n";
}

if ($url =~ m/LB_IP/) {
    die "need real IP instead of LB_IP\n";
}

srand(time);
my @permalinks;
my $http = HTTP::Tiny->new(timeout => 10);

# create pastes in xpaste
for (my $i = 0; $i < $pastes_count; $i++) {
    my $body = generate_body(rand($max_body_size));
    my $resp = $http->post($url, {
        content => $body,
        headers => {
            'Accept'       => '*/*',
            'Content-Type' => 'text/plain',
        },
    });

    die "failed to submit paste: $resp->{reason}\n"
        unless $resp->{success};

    my $permalink = $resp->{content} . '.txt';
    printf STDERR "%.3d %s\n", $i, $permalink;
    push @permalinks, $permalink;
}

# generate targets
for (my $i = 0; $i < $count; $i++) {
    my $link = $permalinks[rand(scalar @permalinks)];

    if ($permalink_alternative_url) {
        $link =~ s#^(https?://[^/]+)#$permalink_alternative_url#;
    }

    if (rand(1) <= $invalid_pcnt) {
        $link =~ s/[a-z0-9]{32}/ffffffffffffffffffffffffffffffff/;
    }

    print "GET $link\n";
}

print STDERR "done\n";

sub generate_body {
    my $size = shift;
    $size /= 8;

    my $body = '';
    while ($size-- >= 0) {
        $body .= sprintf('%08X', rand(0xffffffff));
    }

    return $body;
}

__END__

=head1 NAME

generate-targets-for-slapper.pl - Generate target file for slapper

=head1 SYNOPSIS

generate-targets-for-slapper.pl [options]

 Options:
    --url                       URL to target service (example: http://127.0.0.1/paste)
    --count                     number of bodies to generate (default: 10K)
    --pastes_count              number of pastes to create (default: 100)
    --invalid_pcnt              pecentage of invalid bodies to generate (default: 0.0, accepted range: 0..1)
    --max_body_size             maximal size of generated body (default: 1KB)
    --permalink_alternative_url URL which replaces permalink's URL
    --help                      brief help message

=back

=cut
