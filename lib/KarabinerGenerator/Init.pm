# Init.pm
package KarabinerGenerator::Init;

BEGIN {
    require lib;
    use FindBin;
    my $manifest_path = "$FindBin::Bin/../../newt/ManifestTest";
    lib->import($manifest_path);

    require File::Temp;
    $File::Temp::KEEP_ALL = 1 if $ENV{KEEP_ALL};
}

use strict;
use warnings;
use Exporter 'import';
use Carp qw(croak);
use File::Basename qw(dirname);
use File::Spec;
use FindBin qw($RealBin);
use KarabinerGenerator::DebugUtils qw(db dbd);
use KarabinerGenerator::TestEnvironment qw(
    setup_test_environment
);
use KarabinerGenerator::Config qw(
    get_path
    get_home_directory
    initialize_test_directories
);
use lib "$RealBin/../newt/ManifestTest";
use ManifestTest qw(run_manifest_test);

our @EXPORT_OK = qw(
    init
    is_test_mode
    db
    dbd
);

# State tracking (ALL package variables for testing)
our $INITIALIZED = 0;
our $TEST_MODE;
our $SKIP_TEST_INIT = 0;

# Check if we're in test mode - this needs to be completely deterministic
sub is_test_mode {
    require Test::More;
    db("\n### ENTERING is_test_mode() ###");
    db("Existing TEST_MODE = " . (defined $TEST_MODE ? $TEST_MODE : "undef"));
    db("HARNESS_ACTIVE = " . (defined $ENV{HARNESS_ACTIVE} ? $ENV{HARNESS_ACTIVE} : "undef"));

    # Return cached value if we have one
    return $TEST_MODE if defined $TEST_MODE;

    # Calculate based on existence and truth of HARNESS_ACTIVE
    $TEST_MODE = defined $ENV{HARNESS_ACTIVE} && $ENV{HARNESS_ACTIVE} ? 1 : 0;
    db("Set TEST_MODE to $TEST_MODE");
    return $TEST_MODE;
}


sub init {
    my %opts = @_;
    my $required = exists $opts{required} ? $opts{required} : 1;

    db("\n### ENTERING init() ###");
    db("required = $required");
    db("SKIP_TEST_INIT = $SKIP_TEST_INIT");
    db("TEST_MODE = " . (defined $TEST_MODE ? $TEST_MODE : "undef"));
    db("INITIALIZED = $INITIALIZED");

    return 1 if $INITIALIZED;

    db("About to call get_home_directory");
    my $home = KarabinerGenerator::Config::get_home_directory(required => $required);
    db("Got home directory: " . (defined $home ? $home : "UNDEFINED"));

    if (is_test_mode() && !$SKIP_TEST_INIT) {
        db("Initializing test environment");
        initialize_test_directories();  # Call Config's initialization first
        _initialize_test_environment(); # Then do the rest of test setup

        # Run manifest test
        db("Running manifest test");
        ManifestTest::run_manifest_test() if is_test_mode();
    }

    db("Verifying environment...");
    my $env_status = _verify_environment(required => $required);

    unless ($env_status->{valid_installation}) {
        db("Invalid installation, required=$required");
        croak "Environment verification failed" if $required;
        return 0;
    }

    $INITIALIZED = 1;
    return 1;
}

sub _verify_paths {
    my %opts = @_;
    my $required = exists $opts{required} ? $opts{required} : 1;

    db("\n### ENTERING _verify_paths() ###");
    db("required = $required");

    my @required_paths = qw(
        config_dir
        karabiner_complex_mods_dir
        templates_dir
        generated_json_dir
    );

    my %results;
    for my $path_key (@required_paths) {
        db("Checking path: $path_key");
        eval {
            my $path = get_path($path_key);
            db("Got path: " . (defined $path ? $path : "UNDEFINED"));
            $results{$path_key} = {
                path => $path,
                exists => -e $path,
                is_dir => -d $path,
                is_file => -f $path,
                readable => -r $path,
                writable => -w $path
            };
            db("Path exists: " . ($results{$path_key}{exists} ? "YES" : "NO"));
        };
        if ($@) {
            db("Error getting path: $@");
            $results{$path_key} = {
                path => undef,
                error => $@
            };
        }
    }

    return \%results;
}

sub _verify_environment {
    my %opts = @_;
    my $required = exists $opts{required} ? $opts{required} : 1;

    # Just check the critical paths exist
    my $config_dir = get_path('config_dir');
    my $complex_mods_dir = get_path('karabiner_complex_mods_dir');

    return {
        valid_installation => 1,  # In test mode, always consider valid
    } if is_test_mode();

    # In production, verify actual Karabiner installation
    return {
        valid_installation => (
            -d $config_dir &&
            -d $complex_mods_dir &&
            -f get_path('karabiner_json')
        )
    };
}

sub _check_valid_installation {
    my ($path_status) = @_;

    db("\n### ENTERING _check_valid_installation() ###");
    db("path_status defined: " . (defined $path_status ? "YES" : "NO"));

    unless (defined $path_status) {
        db("path_status undefined, returning 0");
        return 0;
    }

    db("config_dir exists: " . (exists $path_status->{config_dir} ? "YES" : "NO"));
    db("karabiner_json exists: " . (exists $path_status->{karabiner_json} ? "YES" : "NO"));

    if ($path_status->{config_dir}) {
        db("config_dir attributes:");
        db("  exists: " . ($path_status->{config_dir}{exists} ? "YES" : "NO"));
        db("  is_dir: " . ($path_status->{config_dir}{is_dir} ? "YES" : "NO"));
    }

    if ($path_status->{karabiner_json}) {
        db("karabiner_json attributes:");
        db("  exists: " . ($path_status->{karabiner_json}{exists} ? "YES" : "NO"));
        db("  readable: " . ($path_status->{karabiner_json}{readable} ? "YES" : "NO"));
    }

    # Basic directory structure checks
    return 0 unless exists $path_status->{config_dir}
                    && $path_status->{config_dir}{exists}
                    && $path_status->{config_dir}{is_dir};

    # Only check karabiner.json in non-test mode
    if (!is_test_mode()) {
        return 0 unless exists $path_status->{karabiner_json}
                        && $path_status->{karabiner_json}{exists}
                        && $path_status->{karabiner_json}{readable};
    }

    db("All checks passed, returning 1");
    return 1;
}

sub _initialize_test_environment {
    db("\n### ENTERING _initialize_test_environment() ###");

    if ($SKIP_TEST_INIT) {
        db("SKIP_TEST_INIT is set, returning early");
        return 1;
    }

    # Get the paths from Config
    my $project_dir = get_path('project_dir');
    my $karabiner_dir = get_path('karabiner_dir');
    my $output_dir = get_path('output_dir');

    setup_test_environment(
        output_dir => $output_dir,
        project_skeleton_dir => get_path('project_skeleton_dir'),
        karabiner_skeleton_dir => get_path('karabiner_skeleton_dir'),
        project_dir => $project_dir,
        karabiner_dir => $karabiner_dir
    );

    return 1;
}

1;