# newt/TestEnvironment/01_basic.t
use strict;
use warnings;
use Test::Most 'die';
use Test::Exception;
use File::Spec;

use KarabinerGenerator::Config qw(get_path);
use KarabinerGenerator::Init qw(init is_test_mode db);
use KarabinerGenerator::TestEnvironment qw(
    setup_test_environment
);

db("### STARTING TESTENVIRONMENT BASIC TESTS ###");
db("HARNESS_ACTIVE = " . ($ENV{HARNESS_ACTIVE} // "undef"));

# First ensure we're in test mode and initialize Config
ok(is_test_mode(), 'Running in test mode');
lives_ok(
    sub { init() },
    'Environment initialization completed'
);

# Get paths from Config
my $base_test_dir = get_path('output_dir');
my $project_dir = get_path('project_dir');
my $karabiner_dir = get_path('karabiner_dir');

# Test directory creation and naming
subtest 'Test directories' => sub {
    db("Testing test directories");
    
    my $project_dirname = KarabinerGenerator::Config::get_test_project_dirname();
    my $karabiner_dirname = KarabinerGenerator::Config::get_test_karabiner_dirname();
    db("Project dirname: $project_dirname");
    db("Karabiner dirname: $karabiner_dirname");

    like($project_dirname, qr/^project_\w{5}$/, 'Project dirname has correct pattern');
    like($karabiner_dirname, qr/^karabiner_\w{5}$/, 'Karabiner dirname has correct pattern');
    isnt($project_dirname, $karabiner_dirname, 'Directory names are unique');

    # Verify directories exist at correct paths
    db("Project dir: $project_dir");
    db("Karabiner dir: $karabiner_dir");
    
    ok(-d $project_dir, 'Project directory exists at computed path');
    ok(-d $karabiner_dir, 'Karabiner directory exists at computed path');
};

# Test directory structure after setup
subtest 'Directory structure' => sub {
    db("Testing directory structure");
    
    # Check for expected project directory structure
    my @required_dirs = qw(
        yaml_configs
        templates/common
        templates/complex_modifiers
        templates/triggers
        generated_json/complex_modifiers
        generated_json/profiles
        generated_json/triggers
    );
   
    for my $dir (@required_dirs) {
        my $path = File::Spec->catdir($project_dir, split('/', $dir));
        db("Checking directory: $path");
        ok(-d $path, "Directory exists: $dir");
    }
    
    # Check Karabiner structure
    my $assets_dir = File::Spec->catdir($karabiner_dir, 'assets');
    my $complex_mods_dir = File::Spec->catdir($assets_dir, 'complex_modifications');
    
    db("Checking Karabiner structure:");
    db("Assets dir: $assets_dir");
    db("Complex mods dir: $complex_mods_dir");
    
    ok(-d $assets_dir, 'Assets directory exists');
    ok(-d $complex_mods_dir, 'Complex modifications directory exists');
};

# Test directory name consistency
subtest 'Directory name consistency' => sub {
    db("Testing directory name consistency");
    
    my $first_project = KarabinerGenerator::Config::get_test_project_dirname();
    my $first_karabiner = KarabinerGenerator::Config::get_test_karabiner_dirname();
    db("First project dirname: $first_project");
    db("First karabiner dirname: $first_karabiner");
    
    is(KarabinerGenerator::Config::get_test_project_dirname(), $first_project, 
       'Project dirname stays consistent');
    is(KarabinerGenerator::Config::get_test_karabiner_dirname(), $first_karabiner, 
       'Karabiner dirname stays consistent');
};

db("### TESTENVIRONMENT BASIC TESTS COMPLETE ###");
done_testing();