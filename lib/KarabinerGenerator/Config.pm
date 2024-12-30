# Config.pm
package KarabinerGenerator::Config;

our $FORCE_HOME = undef;  # For testing
our $TEST_PROJECT_DIR;
our $TEST_KARABINER_DIR;
our $TEST_OUTPUT_DIR;

use strict;
use warnings;
use Cwd qw(abs_path);
use File::Basename;
use File::Spec;
use File::HomeDir;
use File::Temp qw(tempdir);
use YAML qw(LoadFile);  # Add this import
use Exporter "import";
use File::Path qw(make_path);
use KarabinerGenerator::DebugUtils qw(db);
use KarabinerGenerator::KarabinerInstallation qw(find_karabiner_installation);
use KarabinerGenerator::TestEnvironment qw(
    setup_test_environment
);

our @EXPORT_OK = qw(
    load_config
    get_path
    get_home_directory
    initialize_test_directories
);

# Determine project root once at compile time
my $PROJECT_ROOT = do {
    my $config_path = abs_path(__FILE__);
    my $kg_dir = dirname($config_path);
    my $lib_dir = dirname($kg_dir);
    dirname($lib_dir);
};

my $TEST_DIR = 'newt';  # Can be changed to 't' later

# Cache for paths and state
my %PATHS_CACHE;
my $KARABINER_PATHS;
my $LAST_ENV_STATE;

# Define path configurations once at compile time
my %PATH_CONFIGS = (
    # Project directory structure (relative to base_project_dir)
    lib_dir => ['lib'],
    yaml_configs_dir => ['yaml_configs'],
    templates_dir => ['templates'],
    generated_json_dir => ['generated_json'],

    # Template subdirectories
    triggers_templates_dir => ['templates', 'triggers'],
    complex_mods_templates_dir => ['templates', 'complex_modifiers'],
    common_templates_dir => ['templates', 'common'],

    # Generated JSON subdirectories
    generated_triggers_dir => ['generated_json', 'triggers'],
    generated_complex_mods_dir => ['generated_json', 'complex_modifiers'],
    generated_profiles_dir => ['generated_json', 'profiles'],

    # Configuration files
    template_config_yaml => ['yaml_configs', 'template_config.yaml'],
    global_config_yaml => ['yaml_configs', 'global_config.yaml'],
    profile_config_yaml => ['yaml_configs', 'profile_config.yaml'],

    # Root directories (absolute)
    project_root => $PROJECT_ROOT,
    json_generator_script => File::Spec->catfile($PROJECT_ROOT, 'bin', 'json_generator.pl'),

    # Root test directories (relative to project root)
    output_dir => ['.test_output'],
    project_dir => ['.test_output', 'project'],
    karabiner_dir => ['.test_output', 'karabiner'],

    # Fixtures paths
    fixtures_dir => [$TEST_DIR, 'fixtures'],
    fixtures_project_dir => [$TEST_DIR, 'fixtures', 'project'],
    fixtures_karabiner_dir => [$TEST_DIR, 'fixtures', 'karabiner'],
    fixtures_project_defaults_dir => [$TEST_DIR, 'fixtures', 'project', 'defaults'],
    fixtures_karabiner_defaults_dir => [$TEST_DIR, 'fixtures', 'karabiner', 'defaults'],

    # Skeleton paths
    project_skeleton_dir => [$TEST_DIR, 'fixtures', 'project', 'skeleton'],
    karabiner_skeleton_dir => [$TEST_DIR, 'fixtures', 'karabiner', 'skeleton'],
    skeleton_dir => [$TEST_DIR, 'fixtures', 'project', 'skeleton'],  # Legacy path for backward compatibility
);

sub get_home_directory {
    my %opts = @_;
    my $required = exists $opts{required} ? $opts{required} : 1;

    db("\n### ENTERING get_home_directory() ###");
    db("required = $required");
    db("FORCE_HOME = " . (defined $FORCE_HOME ? $FORCE_HOME : "undef"));

    # Get real home first
    my $real_home = File::HomeDir->my_home;
    db("real_home from File::HomeDir: " . (defined $real_home ? $real_home : "undef"));

    # Use FORCE_HOME if set (for testing)
    my $home = defined $FORCE_HOME ? $FORCE_HOME : $real_home;
    db("Selected home: " . (defined $home ? $home : "undef"));

    # Check existence
    db("home exists? " . (defined $home && -e $home ? "YES" : "NO"));
    db("home is dir? " . (defined $home && -d $home ? "YES" : "NO"));

    unless (defined $home && -d $home) {
        db("Home directory invalid or doesn't exist");
        if ($required) {
            db("About to die - required=$required");
            die "Could not determine home directory";
        }
        db("Returning undef since not required");
        return;
    }

    db("Returning valid home: $home");
    return $home;
}

# Helper function to build paths
sub _build_paths {
    my ($base_dir) = @_;
    db("Building paths with base_dir: $base_dir");
    my %built_paths;

    # Get or initialize Karabiner paths
    unless ($KARABINER_PATHS) {
        db("KARABINER_PATHS not initialized, initializing now");
        if ($ENV{HARNESS_ACTIVE}) {
            db("In test harness, using test paths");
            $KARABINER_PATHS = {
                config_dir => File::Spec->catdir($PROJECT_ROOT, '.test_output', get_test_karabiner_dirname()),
                cli_path => '/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli'
            };
        } else {
            db("In production mode, finding real Karabiner installation");
            $KARABINER_PATHS = find_karabiner_installation();
        }
        db("Karabiner config_dir: " . $KARABINER_PATHS->{config_dir});
        db("Karabiner cli_path: " . $KARABINER_PATHS->{cli_path});
    }

    # Add Karabiner-specific paths
    $built_paths{cli_path} = $KARABINER_PATHS->{cli_path};
    $built_paths{config_dir} = $KARABINER_PATHS->{config_dir};
    $built_paths{karabiner_json} = File::Spec->catfile($KARABINER_PATHS->{config_dir}, 'karabiner.json');
    $built_paths{karabiner_complex_mods_dir} = File::Spec->catdir($KARABINER_PATHS->{config_dir}, 'assets', 'complex_modifications');

    # Build remaining paths
    db("Building remaining paths");
    for my $key (keys %PATH_CONFIGS) {
        my $path_spec = $PATH_CONFIGS{$key};
        if (ref $path_spec eq 'ARRAY') {
            # For fixtures and other source tree paths, use PROJECT_ROOT directly
            if ($key =~ /^fixtures|skeleton_dir$/) {
                $built_paths{$key} = File::Spec->catdir($PROJECT_ROOT, @$path_spec);
            }
            # For test environment paths, use the provided base_dir
            else {
                $built_paths{$key} = File::Spec->catdir($base_dir, @$path_spec);
            }
            db("Built path for $key: " . $built_paths{$key});
        } else {
            $built_paths{$key} = $path_spec;  # For absolute paths
            db("Using absolute path for $key: " . $built_paths{$key});
        }
    }

    return %built_paths;
}

sub get_path {
    my ($resource_name) = @_;
    db("get_path called for: $resource_name");

    # Handle test output paths dynamically when in test environment
    if ($ENV{HARNESS_ACTIVE} && $resource_name =~ /^(output_dir|project_dir|karabiner_dir|karabiner_complex_mods_dir)$/) {
        db("Handling test path for $resource_name");
        my $output_dir = File::Spec->catdir($PROJECT_ROOT, '.test_output');

        return $output_dir if $resource_name eq 'output_dir';

        my $dirname = $resource_name eq 'project_dir' ?
            get_test_project_dirname() : get_test_karabiner_dirname();
        db("Test dirname: $dirname");

        my $base_path = File::Spec->catdir($output_dir, $dirname);
        my $final_path = $resource_name eq 'karabiner_complex_mods_dir' ?
            File::Spec->catdir($base_path, 'assets', 'complex_modifications') :
            $base_path;

        db("Returning test path: $final_path");
        return $final_path;
    }

    # Use cache for all other paths
    unless (%PATHS_CACHE) {
        my $base_dir = $ENV{HARNESS_ACTIVE} ?
            File::Spec->catdir($PROJECT_ROOT, '.test_output', get_test_project_dirname()) :
            $PROJECT_ROOT;
        db("Initializing PATHS_CACHE with base_dir: $base_dir");
        %PATHS_CACHE = _build_paths($base_dir);
    }

    die "Unknown resource: $resource_name"
        unless exists $PATHS_CACHE{$resource_name};

    db("Returning path for $resource_name: " . $PATHS_CACHE{$resource_name});
    return $PATHS_CACHE{$resource_name};
}

# Update load_config in Config.pm

my $load_count = 0;

sub load_config {
    $load_count++;
    db("\n### ENTERING load_config() [call #$load_count] ###");
    my (undef, $file, $line) = caller;
    db("Called from: $file:$line");
    my $config = {};
    my $template_config_path = get_path('template_config_yaml');
    my $global_config_path = get_path('global_config_yaml');
    my $profile_config_path = get_path('profile_config_yaml');

    # Load template config if it exists
    if (-f $template_config_path) {
        $config = eval { LoadFile($template_config_path) } || {};
    } else {
        warn "No template config found at $template_config_path\n";
    }

    # Load global config if it exists
    my $global_config = {};
    if (-f $global_config_path) {
        $global_config = eval { LoadFile($global_config_path) } || {};

        # Process any path expansions in the global config
        if ($global_config && $global_config->{karabiner}) {
            my $k = $global_config->{karabiner};
            for my $path_key (qw(config_dir complex_mods_dir cli_path)) {
                if ($k->{$path_key}) {
                    $k->{$path_key} =~ s/^~/$ENV{HOME}/;
                }
            }
        }
    }

    # Load profile config if it exists
    my $profile_config = {};
    if (-f $profile_config_path) {
        $profile_config = eval { LoadFile($profile_config_path) } || {};
    }

    # Add configs under their respective keys
    $config->{global} = $global_config;
    $config->{profiles} = $profile_config;

    return $config;
}

sub initialize_test_directories {
    return unless $ENV{HARNESS_ACTIVE}; # Only run in test mode

    db("\n### ENTERING initialize_test_directories() ###");

    # Create .test_output if it doesn't exist
    $TEST_OUTPUT_DIR = File::Spec->catdir($PROJECT_ROOT, '.test_output');
    make_path($TEST_OUTPUT_DIR) unless -d $TEST_OUTPUT_DIR;

    # Create temporary project and karabiner directories
    $TEST_PROJECT_DIR = tempdir('project_XXXXX', DIR => $TEST_OUTPUT_DIR, CLEANUP => 1);
    $TEST_KARABINER_DIR = tempdir('karabiner_XXXXX', DIR => $TEST_OUTPUT_DIR, CLEANUP => 1);

    db("Created test directories:");
    db("  OUTPUT_DIR: $TEST_OUTPUT_DIR");
    db("  PROJECT_DIR: $TEST_PROJECT_DIR");
    db("  KARABINER_DIR: $TEST_KARABINER_DIR");

    return 1;
}

sub get_test_project_dirname {
    die "Test environment not initialized" unless defined $TEST_PROJECT_DIR;
    return (File::Spec->splitpath($TEST_PROJECT_DIR))[-1];
}

sub get_test_karabiner_dirname {
    die "Test environment not initialized" unless defined $TEST_KARABINER_DIR;
    return (File::Spec->splitpath($TEST_KARABINER_DIR))[-1];
}


1;