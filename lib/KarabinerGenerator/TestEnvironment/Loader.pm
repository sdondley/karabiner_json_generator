# lib/KarabinerGenerator/TestEnvironment/Loader.pm
package KarabinerGenerator::TestEnvironment::Loader;

use strict;
use warnings;
use Exporter 'import';
use Carp qw(croak);
use File::Copy::Recursive qw(dircopy);
use File::Basename qw(dirname basename);
use File::Spec;
use KarabinerGenerator::DebugUtils qw(db);
use KarabinerGenerator::Config qw(get_path);
use KarabinerGenerator::Init qw(is_test_mode);

our @EXPORT_OK = qw(
    load_project_defaults
    load_karabiner_defaults
    load_test_fixtures
);

sub _copy_directory_contents {
    my ($src, $dest) = @_;
    db("\n### ENTERING _copy_directory_contents ###");
    db("Source: $src");
    db("Destination: $dest");

    croak "Source directory does not exist: $src" unless -d $src;

    db("Source exists: " . (-d $src ? "YES" : "NO"));
    db("Source readable: " . (-r $src ? "YES" : "NO"));
    db("Dest exists: " . (-d $dest ? "YES" : "NO"));
    db("Dest writable: " . (-w $dest ? "YES" : "NO"));

    db("Source directory contents:");
    if (opendir(my $dh, $src)) {
        while(my $f = readdir($dh)) {
            db("  $f");
        }
        closedir($dh);
    }

    db("About to copy directory contents");
    my $result = File::Copy::Recursive::dircopy($src, $dest);
    db("dircopy result: " . ($result ? "SUCCESS" : "FAILED: $!"));

    return $result || croak "Failed to copy $src to $dest: $!";
}

sub load_project_defaults {
    my ($test_dir) = @_;
    db("\n### ENTERING load_project_defaults() ###");

    my $src = $test_dir || get_path('fixtures_project_defaults_dir');
    my $dest = get_path('project_dir');

    db("Loading project defaults from $src to $dest");
    return _copy_directory_contents($src, $dest);
}

sub load_karabiner_defaults {
    my ($test_dir) = @_;
    db("\n### ENTERING load_karabiner_defaults() ###");

    my $src = $test_dir || get_path('fixtures_karabiner_defaults_dir');
    my $dest = get_path('karabiner_dir');

    db("Loading Karabiner defaults from $src to $dest");
    return _copy_directory_contents($src, $dest);
}


sub load_test_fixtures {
    db("\n### ENTERING load_test_fixtures() ###");

    # Get test file location by walking up the caller stack
    my $test_file;
    for (my $i = 0; $i < 5; $i++) {  # Check up to 5 levels up the stack
        my (undef, $filename, undef) = caller($i);
        db("Checking caller level $i: " . ($filename // "undef"));
        if ($filename && $filename =~ /\.t$/) {
            $test_file = $filename;
            db("Found test file at caller level $i: $test_file");
            last;
        }
    }

    croak "Could not determine test file location" unless $test_file;

    # Get the test number
    my $test_num = _get_test_number($test_file);
    db("Test number: $test_num");

    # Get absolute paths
    my $test_dir = dirname($test_file);
    db("Test directory: $test_dir");

    # Construct fixture paths using File::Spec for cross-platform compatibility
    my $fixtures_dir = File::Spec->catdir($test_dir, 'fixtures', $test_num);
    my $project_fixtures = File::Spec->catdir($fixtures_dir, 'project');
    my $karabiner_fixtures = File::Spec->catdir($fixtures_dir, 'karabiner');

    db("Fixtures directory: $fixtures_dir");
    db("Project fixtures: $project_fixtures");
    db("Karabiner fixtures: $karabiner_fixtures");

    # Load project fixtures if they exist
    if (-d $project_fixtures) {
        db("Loading project fixtures from $project_fixtures");
        _copy_directory_contents($project_fixtures, get_path('project_dir'));
    } else {
        db("No project fixtures found at $project_fixtures");
    }

    # Load karabiner fixtures if they exist
    if (-d $karabiner_fixtures) {
        db("Loading karabiner fixtures from $karabiner_fixtures");
        _copy_directory_contents($karabiner_fixtures, get_path('karabiner_dir'));
    } else {
        db("No karabiner fixtures found at $karabiner_fixtures");
    }

    return 1;
}

sub _get_test_number {
    my ($filename) = @_;
    db("Getting test number from filename: $filename");

    if ($filename =~ /(\d+)_.*?\.t$/) {
        my $test_num = $1;
        db("Found test number: $test_num");
        return $test_num;
    }

    croak "Could not determine test number from filename: $filename";
}

1;