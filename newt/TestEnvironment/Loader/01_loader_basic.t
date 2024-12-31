# newt/TestEnvironment/Loader/01_loader_basic.t 
use strict;
use warnings;
use Test::Most 'die';
use Test::Exception;

use KarabinerGenerator::Init qw(init is_test_mode db);
use KarabinerGenerator::Config qw(get_path);
use KarabinerGenerator::TestEnvironment qw(
    setup_test_environment
);
use KarabinerGenerator::TestEnvironment::Loader qw(
    load_project_defaults
    load_karabiner_defaults
);

db("### STARTING LOADER BASIC TESTS ###");
db("HARNESS_ACTIVE = " . ($ENV{HARNESS_ACTIVE} // "undef"));

# Initialize FIRST
lives_ok(
    sub { init() },
    'Environment initialization completed'
);

# First ensure we're in test mode
ok(is_test_mode(), 'Running in test mode');

# Test basic fixture loading
subtest 'Basic fixture loading' => sub {
    db("Testing basic fixture loading");
    db("Project defaults dir: " . get_path('fixtures_project_defaults_dir')); 
    db("Karabiner defaults dir: " . get_path('fixtures_karabiner_defaults_dir'));
    db("Template config path: " . get_path('template_config_yaml'));
    
    lives_ok(
        sub { load_project_defaults() },
        'Project defaults loaded successfully'
    );
    
    lives_ok(
        sub { load_karabiner_defaults() },
        'Karabiner defaults loaded successfully'
    );

    my $template_config = get_path('template_config_yaml');
    ok(-f $template_config, 'template_config.yaml exists');
};

# Test error handling
subtest 'Error handling' => sub {
    db("Testing error handling");
    
    throws_ok { 
        load_project_defaults('/nonexistent/path/that/cannot/exist') 
    } qr/Source directory does not exist/, 
        'Throws error when source directory does not exist';
};

db("### LOADER BASIC TESTS COMPLETE ###");
done_testing();