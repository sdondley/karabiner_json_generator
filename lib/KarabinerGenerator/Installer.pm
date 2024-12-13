package KarabinerGenerator::Installer;
use strict;
use warnings;
use File::Copy;
use File::Path qw(make_path);
use File::Basename qw(basename);
use File::Spec;
use Exporter "import";

our @EXPORT_OK = qw(install_files);

sub install_files {
    my ($dest_dir, @source_files) = @_;

    # Validate input
    return 0 unless defined $dest_dir && @source_files;

    # Create destination directory if it doesn't exist
    eval {
        make_path($dest_dir) unless -d $dest_dir;
    };
    if ($@) {
        warn "Could not create directory $dest_dir: $@\n";
        return 0;
    }

    my $success = 1;
    foreach my $source_file (@source_files) {
        # Skip if source file doesn't exist
        unless (-f $source_file) {
            warn "Source file does not exist: $source_file\n";
            $success = 0;
            next;
        }

        # Get just the filename for the destination
        my $filename = basename($source_file);
        my $dest_file = File::Spec->catfile($dest_dir, $filename);

        # Attempt to copy the file
        if (!copy($source_file, $dest_file)) {
            warn "Failed to copy $source_file to $dest_file: $!\n";
            $success = 0;
            next;
        }

        # Set permissions to match original or make readable
        eval {
            my $mode = (stat($source_file))[2] & 07777;
            chmod($mode, $dest_file);
        };
        if ($@) {
            warn "Failed to set permissions on $dest_file: $@\n";
            # Don't fail the whole operation for permission issues
        }
    }

    return $success;
}

1;