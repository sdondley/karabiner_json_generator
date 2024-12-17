package KarabinerGenerator::Config;

use strict;
use warnings;
use YAML::XS qw(LoadFile);
use File::Spec;
use File::Basename;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::Copy::Recursive qw(dircopy);
use Cwd qw(getcwd abs_path);
use Exporter "import";

our @EXPORT_OK = qw(load_config get_path mode reset_test_environment);

# Determine project root once at compile time
my $PROJECT_ROOT = do {
    my $config_path = abs_path(__FILE__);
    my $kg_dir = dirname($config_path);
    my $lib_dir = dirname($kg_dir);
    dirname($lib_dir);
};

# Single state variable for mode
my $MODE;

# Single hash containing all paths
my $PATHS;

# Keep track of current test environment
my $CURRENT_TEST_ENV;

# Mode getter/setter
sub mode {
    my $new_mode = shift;
    if (defined $new_mode) {
        die "Invalid mode: $new_mode" unless $new_mode =~ /^(test|prod)$/;
        $MODE = $new_mode;
    }
    return $MODE;
}

# Initialize mode based on test harness
BEGIN {
    mode($ENV{HARNESS_ACTIVE} ? 'test' : 'prod');
}

# New function to reset test environment
sub reset_test_environment {
    if ($PATHS && $PATHS->{test}) {
        delete $PATHS->{test};
        undef $CURRENT_TEST_ENV;
    }
}

sub path_in {
    my ($base_path, @components) = @_;
    return File::Spec->catfile($base_path, @components) if $components[-1] =~ /\./;
    return File::Spec->catdir($base_path, @components);
}

sub _setup_test_environment {
    # Return existing environment if it exists and is valid
    return $PATHS->{test} if $PATHS->{test} && $CURRENT_TEST_ENV && -d $CURRENT_TEST_ENV;

    # Create temp directory for test files
    my $temp_dir = tempdir(CLEANUP => 1);
    $CURRENT_TEST_ENV = $temp_dir;

    # Get fixture paths
    my $fixtures_dir = path_in($PROJECT_ROOT, 't', 'fixtures');
    my $project_mockup = path_in($fixtures_dir, 'mockups', 'project');
    my $karabiner_mockup = path_in($fixtures_dir, 'mockups', 'karabiner');

    # Create required directories in temp dir
    for my $dir (qw(generated_json templates complex_modifications)) {
        make_path(path_in($temp_dir, $dir));
    }

    # Copy project mockup files to temp directory
    dircopy($project_mockup, $temp_dir) or die "Failed to copy project mockup: $!";
    dircopy($karabiner_mockup, $temp_dir) or die "Failed to copy project mockup: $!";

    my $env_vars = "TEST_MODE=1";
    $env_vars .= " QUIET=1" if $ENV{FORCE_QUIET};

    # Set up fresh test paths
    $PATHS->{test} = {
        cli_path => '/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli',
        config_dir => $karabiner_mockup,
        complex_mods_dir => path_in($temp_dir, 'assets', 'complex_modifications'),
        templates_dir => path_in($temp_dir, 'templates'),
        generated_json_dir => path_in($temp_dir, 'generated_json'),
        config_yaml => path_in($temp_dir, 'config.yaml'),
        global_config_yaml => path_in($temp_dir, 'global_config.yaml'),
        karabiner_json => path_in($karabiner_mockup, 'karabiner.json'),
        complex_modifiers_json => path_in($temp_dir, 'complex_modifiers.json'),
        valid_complex_mod => path_in($fixtures_dir, 'valid_complex_mod.json'),
        invalid_complex_mod => path_in($fixtures_dir, 'invalid_complex_mod.json'),
        malformed_complex_mod => path_in($fixtures_dir, 'malformed_complex_mod.json'),
        json_generator => "$env_vars " . path_in($PROJECT_ROOT, 'bin', 'json_generator.pl'),
    };

    return $PATHS->{test};
}

sub _setup_prod_environment {
    return $PATHS->{prod} if $PATHS->{prod};

    my $config_dir = "/Users/$ENV{USER}/.config/karabiner";

    # Build all paths with absolute paths
    $PATHS->{prod} = {
        cli_path => '/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli',
        config_dir => $config_dir,
        complex_mods_dir => path_in($PROJECT_ROOT, 'assets', 'complex_modifications'),
        templates_dir => path_in($PROJECT_ROOT, 'templates'),
        generated_json_dir => path_in($PROJECT_ROOT, 'generated_json'),
        config_yaml => path_in($PROJECT_ROOT, 'config.yaml'),
        global_config_yaml => path_in($PROJECT_ROOT, 'global_config.yaml'),
        karabiner_json => path_in($config_dir, 'karabiner.json'),
        complex_modifiers_json => path_in($PROJECT_ROOT, 'complex_modifiers.json'),
        json_generator => path_in($PROJECT_ROOT, 'bin', 'json_generator.pl'),
    };

    # If we have global config overrides, apply them
    if (-f $PATHS->{prod}{global_config_yaml}) {
        my $config = eval { LoadFile($PATHS->{prod}{global_config_yaml}) } || {};
        if ($config && $config->{karabiner}) {
            my $k = $config->{karabiner};
            # Expand any ~ in the override paths
            for my $path_key (qw(config_dir complex_mods_dir cli_path)) {
                if ($k->{$path_key}) {
                    $k->{$path_key} =~ s/^~/$ENV{HOME}/;
                    $PATHS->{prod}{$path_key} = $k->{$path_key};
                }
            }
        }
    }

    return $PATHS->{prod};
}

sub get_path {
    my ($resource_name) = @_;

    _setup_prod_environment();

    # Initialize paths based on mode
    if ($MODE eq 'test') {
        _setup_test_environment();
    }

    die "Unknown resource: $resource_name"
        unless exists $PATHS->{$MODE}{$resource_name};

    return $PATHS->{$MODE}{$resource_name};
}

sub load_config {
    # Get paths
    my $config = eval { LoadFile(get_path('config_yaml')) } || {};
    my $global_config = eval { LoadFile(get_path('global_config_yaml')) } || {};
    $config->{global} = $global_config;
    return $config;
}

1;