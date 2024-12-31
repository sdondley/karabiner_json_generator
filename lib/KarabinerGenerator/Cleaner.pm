# lib/KarabinerGenerator/Cleaner.pm
package KarabinerGenerator::Cleaner;

use strict;
use warnings;
use File::Find;
use File::Spec;
use File::Basename qw(basename dirname);
use Exporter 'import';
use KarabinerGenerator::Config qw(get_path);
use KarabinerGenerator::Init qw(db dbd);

our @EXPORT_OK = qw(
    find_generated_files
    clean_generated_files
);

sub _is_hidden_path {
    my ($dir) = @_;
    my @parts = File::Spec->splitdir($dir);
    for my $part (@parts) {
        return 1 if $part =~ /^\./;
    }
    return 0;
}

sub find_generated_files {
    db("\n### ENTERING find_generated_files() ###");

    my $generated_json_dir = get_path('generated_json_dir');
    db("Looking for files in: $generated_json_dir");

    unless (-d $generated_json_dir) {
        db("Directory does not exist: $generated_json_dir");
        return ();
    }

    my @found_files;
    my $generated_json_base = basename($generated_json_dir);
    db("Checking files in directory: $generated_json_base");

    File::Find::find(
        {
            wanted => sub {
                my $name = basename($_);
                my $path = $File::Find::name;
                my $rel_path = File::Spec->abs2rel($path, $generated_json_dir);

                db("Checking file: $path");
                db("  name: $name");
                db("  relative path: $rel_path");

                # Skip hidden files or files in hidden directories
                if (_is_hidden_path($rel_path)) {
                    db("  Skipping: hidden path component");
                    return;
                }

                # Only collect .json files
                unless (-f && /\.json$/) {
                    db("  Skipping: not a .json file") if -f;
                    return;
                }

                db("  Adding file: $path");
                push @found_files, $path;
            },
            no_chdir => 1
        },
        $generated_json_dir
    );

    # Sort for consistent ordering
    @found_files = sort @found_files;

    my $count = scalar(@found_files);
    db("Found $count files:");
    for my $file (@found_files) {
        db("  $file");
    }

    return @found_files;
}

sub clean_generated_files {
    db("\n### ENTERING clean_generated_files() ###");

    my @files = find_generated_files();
    my $count = 0;

    for my $file (@files) {
        db("Deleting file: $file");
        if (unlink $file) {
            $count++;
        } else {
            warn "Failed to delete $file: $!";
        }
    }

    db("Deleted $count files");
    return $count;
}

1;