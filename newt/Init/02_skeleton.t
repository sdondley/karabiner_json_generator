# newt/Init/02_skeleton.t
use strict;
use warnings;
use Test::Most 'die';
use KarabinerGenerator::Init qw(init is_test_mode db);
use KarabinerGenerator::Config qw(get_path);

db("\n### STARTING SKELETON TESTS ###");
db("HARNESS_ACTIVE = " . ($ENV{HARNESS_ACTIVE} // "undef"));

# Test basic environment setup
subtest 'Test skeleton initialization' => sub {
    db("Starting skeleton initialization tests");
    
    # Initialize test environment first
    db("Checking test mode status");
    ok(is_test_mode(), 'Running in test mode');
    
    db("Attempting environment initialization");
    lives_ok(
        sub { init() },
        'Environment initialization completed'
    );

    # Now safe to use Config
    db("Getting project directory path");
    my $project_dir = get_path('project_dir');
    db("Project directory: $project_dir");
    ok(-d $project_dir, 'Project directory exists');
    
    # Check skeleton structure
    db("\nVerifying directory structure:");
    for my $dir (qw(
        yaml_configs
        templates/common
        templates/complex_modifiers
        templates/triggers
        generated_json/complex_modifiers
        generated_json/profiles
        generated_json/triggers
    )) {
        my $path = "$project_dir/$dir";
        db("Checking directory: $path");
        ok(-d $path, "Directory exists: $dir");
    }
    
    db("Skeleton structure verification complete");
};

db("### SKELETON TESTS COMPLETE ###");
done_testing();