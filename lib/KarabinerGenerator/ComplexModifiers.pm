package KarabinerGenerator::ComplexModifiers;

use strict;
use warnings;
use JSON::PP;
use File::Copy;
use File::Path qw(make_path);
use File::Basename;
use Try::Tiny;
use Exporter 'import';

our @EXPORT_OK = qw(validate_complex_modifiers install_complex_modifiers);
use KarabinerGenerator::CLI qw(run_ke_cli_cmd);

sub validate_complex_modifiers {
    my ($file) = @_;

    return 0 unless -f $file;

    my $result = run_ke_cli_cmd(['--lint-complex-modifications', $file]);

    # Return 1 for success (status 0), 0 for any failure
    return $result->{status} == 0;
}

sub install_complex_modifiers {
    my ($source, $dest_dir) = @_;

    # Validate source file
    unless (validate_complex_modifiers($source)) {
        warn "Invalid complex modifier file: $source";
        return 0;
    }

    # Create destination directory if it doesn't exist
    try {
        make_path($dest_dir) unless -d $dest_dir;
    } catch {
        warn "Could not create destination directory: $_";
        return 0;
    };

    # Copy file to destination
    my $dest_file = File::Spec->catfile($dest_dir, basename($source));
    try {
        copy($source, $dest_file) or die $!;
    } catch {
        warn "Failed to copy file: $_";
        return 0;
    };

    return -f $dest_file;
}

1;