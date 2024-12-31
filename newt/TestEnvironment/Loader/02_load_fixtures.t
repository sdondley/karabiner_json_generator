# newt/TestEnvironment/Loader/02_load_fixtures.t
use strict;
use warnings;
use Test::Most 'die';
use Test::Exception;
use File::Path qw(rmtree);  # Added rmtree import

use KarabinerGenerator::Init qw(init is_test_mode db);
use KarabinerGenerator::Config qw(get_path);
use KarabinerGenerator::TestEnvironment qw(setup_test_environment);
use KarabinerGenerator::TestEnvironment::Loader qw(
    load_project_defaults
    load_karabiner_defaults
    load_test_fixtures
);

db("### STARTING LOADER FIXTURE TESTS ###");

# Initialize FIRST
lives_ok(
    sub { init() },
    'Environment initialization completed'
);

# Ensure we're in test mode
ok(is_test_mode(), 'Running in test mode');

# Test loading test-specific fixtures
subtest 'Test-specific fixture loading' => sub {
    db("Testing fixture loading for current test");
    
    lives_ok(
        sub { load_test_fixtures() },
        'Test fixtures loaded successfully'
    );

    # Check project files
    my $project_dir = get_path('project_dir');
    ok(-f "$project_dir/templates/test.json.tpl", 'Project template file exists');
    ok(-f "$project_dir/yaml_configs/test_config.yaml", 'Project config file exists');

    # Check karabiner files
    my $karabiner_dir = get_path('karabiner_dir');
    ok(-f "$karabiner_dir/assets/complex_modifications/test.json", 'Karabiner complex mod file exists');
    ok(-f "$karabiner_dir/karabiner.json", 'Karabiner config file exists');
};

# Test loading both default and test fixtures
subtest 'Combined fixture loading' => sub {
    db("Testing combined fixture loading");
    
    lives_ok(
        sub { 
            load_project_defaults();
            load_karabiner_defaults();
            load_test_fixtures();
        },
        'Default and test fixtures loaded successfully'
    );
    
    # Verify default project files exist (assuming these exist in defaults)
    my $project_dir = get_path('project_dir');
    ok(-d "$project_dir/templates", 'Default project templates directory exists');
    ok(-d "$project_dir/yaml_configs", 'Default project configs directory exists');

    # Verify test-specific files still exist after loading defaults
    ok(-f "$project_dir/templates/test.json.tpl", 'Test template file exists after loading defaults');
    ok(-f "$project_dir/yaml_configs/test_config.yaml", 'Test config file exists after loading defaults');

    # Verify karabiner files
    my $karabiner_dir = get_path('karabiner_dir');
    ok(-f "$karabiner_dir/assets/complex_modifications/test.json", 'Test complex mod file exists after loading defaults');
    ok(-f "$karabiner_dir/karabiner.json", 'Test karabiner config exists after loading defaults');
};

# Test with non-existent fixtures
subtest 'Non-existent fixture handling' => sub {
    db("Testing non-existent fixture handling");
    
    # Try loading fixtures from a non-existent test number
    no warnings 'redefine';
    local *KarabinerGenerator::TestEnvironment::Loader::_get_test_number = sub { return "99" };
    
    lives_ok(
        sub { load_test_fixtures() },
        'Handles non-existent fixtures gracefully'
    );
};

# Clean up test directories
sub cleanup_test_directories {
    my $project_dir = get_path('project_dir');
    my $karabiner_dir = get_path('karabiner_dir');
    
    if (-d $project_dir) {
        rmtree($project_dir) or warn "Could not remove project directory: $!";
    }
    if (-d $karabiner_dir) {
        rmtree($karabiner_dir) or warn "Could not remove karabiner directory: $!";
    }
}

END {
    cleanup_test_directories();
}

db("### LOADER FIXTURE TESTS COMPLETE ###");
done_testing();