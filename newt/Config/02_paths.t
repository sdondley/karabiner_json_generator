# newt/Config/02_paths.t
use strict;
use warnings;
use Test::Most 'die';
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use File::Spec;

use KarabinerGenerator::Config qw(get_path);
use KarabinerGenerator::Init qw(init is_test_mode db);

db("### STARTING PATH TESTS ###");
db("HARNESS_ACTIVE = " . ($ENV{HARNESS_ACTIVE} // "undef"));

# Ensure we're in test mode and initialized before starting
subtest 'Environment setup' => sub {
    db("Testing environment setup");
    ok(is_test_mode(), 'Running in test mode');
    lives_ok(
        sub { init() },
        'Environment initialization completed'
    );
};

# Test base paths that don't change between environments
subtest 'Core paths' => sub {
    db("Testing core paths");
    
    my $project_root = get_path('project_root');
    db("Project root path: $project_root");
    ok(defined $project_root, 'Project root is defined');
    ok(-d $project_root, 'Project root exists');
    ok(File::Spec->file_name_is_absolute($project_root), 'Project root is an absolute path');
    
    my $fixtures_dir = get_path('fixtures_dir');
    db("Fixtures directory path: $fixtures_dir");
    ok(defined $fixtures_dir, 'Fixtures dir is defined');
    ok(-d $fixtures_dir, 'Fixtures dir exists');

    my $json_generator = get_path('json_generator_script');
    db("JSON generator script path: $json_generator");
    ok(defined $json_generator, 'JSON generator script path is defined');
    ok(-f $json_generator, 'JSON generator script exists');
    like($json_generator, qr/bin\/json_generator\.pl$/, 'JSON generator script has correct name');

};

# Test test mode paths are set up correctly
subtest 'Test mode path configuration' => sub {
    db("Testing test mode path configuration");
    
    # Verify we're in test mode
    ok($ENV{HARNESS_ACTIVE}, 'Running in test mode');
    
    # Get important project paths
    my %paths = (
        yaml_configs => get_path('yaml_configs_dir'),
        templates => get_path('templates_dir'),
        generated_json => get_path('generated_json_dir')
    );
    
    for my $key (sort keys %paths) {
        db("Test $key path: $paths{$key}");
        
        like(
            $paths{$key},
            qr/\.test_output.*project_[a-zA-Z0-9_]{5}/,
            "$key path is in test project directory"
        );
        
        ok(
            -d $paths{$key},
            "$key directory exists"
        );
    }
};

# Test path caching
subtest 'Path caching' => sub {
    db("Testing path caching");
    
    # Test getting same path multiple times
    db("Testing path consistency");
    my $first_project_dir = get_path('project_dir');
    my $second_project_dir = get_path('project_dir');
    db("First project_dir: $first_project_dir");
    db("Second project_dir: $second_project_dir");
    is($first_project_dir, $second_project_dir, 'Same project_dir path returned');
    
    my $first_templates_dir = get_path('templates_dir');
    my $second_templates_dir = get_path('templates_dir');
    db("First templates_dir: $first_templates_dir");
    db("Second templates_dir: $second_templates_dir");
    is($first_templates_dir, $second_templates_dir, 'Same templates_dir path returned');
       
    # Test cache invalidation with new init
    db("Testing cache invalidation");
    my $first_dir = get_path('project_dir');
    db("First project directory: $first_dir");
    
    no warnings 'once';
    local $KarabinerGenerator::Init::INITIALIZED = 0;
    init();
    my $second_dir = get_path('project_dir');
    db("Second project directory after new init: $second_dir");
    
    isnt($first_dir, $second_dir, 'Cache invalidated after new init');
};

# Test error handling
subtest 'Error handling' => sub {
    db("Testing error handling");
    throws_ok(
        sub { get_path('nonexistent_path') },
        qr/Unknown resource: nonexistent_path/,
        'Dies on unknown path resource'
    );
};

db("### PATH TESTS COMPLETE ###");
done_testing();