package KarabinerGenerator::Utils;
use strict;
use warnings;
use Exporter "import";

our @EXPORT_OK = qw(expand_path);

sub expand_path {
    my ($path) = @_;
    $path =~ s/^~/$ENV{HOME}/;
    return $path;
}

1;

