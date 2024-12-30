# lib/KarabinerGenerator/TestEnvironment.pm
package KarabinerGenerator::TestEnvironment;

use strict;
use warnings;
use Carp qw(croak);
use Exporter "import";
use File::Path qw(make_path);
use File::Copy::Recursive qw(dircopy);
use KarabinerGenerator::DebugUtils qw(db);


our @EXPORT_OK = qw(
    setup_test_environment
    copy_project_skeleton
    copy_karabiner_skeleton
);

sub copy_project_skeleton {
    my ($source, $dest) = @_;
    db("\n### ENTERING copy_project_skeleton() ###");
    db("Source: $source");
    db("Destination: $dest");
    dircopy($source, $dest) or croak "Failed to copy project skeleton: $!";
    return 1;
}

sub copy_karabiner_skeleton {
    my ($source, $dest) = @_;
    db("\n### ENTERING copy_karabiner_skeleton() ###");
    db("Source: $source");
    db("Destination: $dest");
    dircopy($source, $dest) or croak "Failed to copy karabiner skeleton: $!";
    return 1;
}

sub setup_test_environment {
    my %opts = @_;
    db("\n### ENTERING setup_test_environment() ###");

    my $project_dir = $opts{project_dir} or croak "project_dir is required";
    my $karabiner_dir = $opts{karabiner_dir} or croak "karabiner_dir is required";
    my $project_skeleton_dir = $opts{project_skeleton_dir} or croak "project_skeleton_dir is required";
    my $karabiner_skeleton_dir = $opts{karabiner_skeleton_dir} or croak "karabiner_skeleton_dir is required";

    db("Using project directory: $project_dir");
    db("Using karabiner directory: $karabiner_dir");
    db("Using project skeleton: $project_skeleton_dir");
    db("Using karabiner skeleton: $karabiner_skeleton_dir");

    # Copy skeleton structures
    copy_project_skeleton($project_skeleton_dir, $project_dir);
    copy_karabiner_skeleton($karabiner_skeleton_dir, $karabiner_dir);

    db("Test environment setup completed successfully");
    return 1;
}

1;