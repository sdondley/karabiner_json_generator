# newt/Config/03_karabiner_paths.t
use strict;
use warnings;
use Test::Most 'die';
use Test::Exception;

use KarabinerGenerator::Config qw(get_path);
use KarabinerGenerator::Init qw(init is_test_mode db);
use KarabinerGenerator::TestEnvironment qw(
    setup_test_environment
);

db("### STARTING KARABINER PATHS TESTS ###");
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

# Test Karabiner fixture paths (consistent in both environments)
subtest 'Karabiner fixture paths' => sub {
    db("Testing Karabiner fixture paths");
    
    my $karabiner_skeleton = get_path('karabiner_skeleton_dir');
    db("Karabiner skeleton path: $karabiner_skeleton");
    ok(defined $karabiner_skeleton, 'Karabiner skeleton path is defined');
    like($karabiner_skeleton, qr/fixtures.*karabiner.*skeleton$/, 
         'Karabiner skeleton path has correct structure');
    ok(-d $karabiner_skeleton, 'Karabiner skeleton directory exists');

    my $karabiner_defaults = get_path('fixtures_karabiner_defaults_dir');
    db("Karabiner defaults path: $karabiner_defaults");
    ok(defined $karabiner_defaults, 'Karabiner defaults path is defined');
    like($karabiner_defaults, qr/fixtures.*karabiner.*defaults$/, 
         'Karabiner defaults path has correct structure');
    ok(-d $karabiner_defaults, 'Karabiner defaults directory exists');
};

# Test Karabiner paths in test environment
subtest 'Test environment Karabiner paths' => sub {
    db("Testing Karabiner paths in test environment");
    
    my $config_dir = get_path('config_dir');
    my $complex_mods_dir = get_path('karabiner_complex_mods_dir');
    my $karabiner_json = get_path('karabiner_json');

    db("Config directory: $config_dir");
    db("Complex mods directory: $complex_mods_dir");
    db("Karabiner.json path: $karabiner_json");

    # Test basic path structure
    like($config_dir, qr/\.test_output.*karabiner_[a-zA-Z0-9_]{5}/, 
         'Config dir is in test environment');
    like($complex_mods_dir, qr/\.test_output.*karabiner_[a-zA-Z0-9_]{5}.*assets.*complex_modifications$/, 
         'Complex mods dir has correct structure');
    like($karabiner_json, qr/\.test_output.*karabiner_[a-zA-Z0-9_]{5}.*karabiner\.json$/, 
         'Karabiner.json has correct path structure');
};

# Test path consistency
subtest 'Path consistency' => sub {
    db("Testing path consistency");
    
    my $first_config_dir = get_path('config_dir');
    my $second_config_dir = get_path('config_dir');
    db("First config_dir: $first_config_dir");
    db("Second config_dir: $second_config_dir");
    is($first_config_dir, $second_config_dir, 'Config dir path is consistent');

    my $first_complex_mods = get_path('karabiner_complex_mods_dir');
    my $second_complex_mods = get_path('karabiner_complex_mods_dir');
    db("First complex_mods: $first_complex_mods");
    db("Second complex_mods: $second_complex_mods");
    is($first_complex_mods, $second_complex_mods, 'Complex mods path is consistent');
};

# Test relative path relationships
subtest 'Path relationships' => sub {
    db("Testing path relationships");
    
    my $config_dir = get_path('config_dir');
    my $complex_mods_dir = get_path('karabiner_complex_mods_dir');
    
    db("Checking relative path relationship");
    db("Config dir: $config_dir");
    db("Complex mods dir: $complex_mods_dir");
    
    like(
        $complex_mods_dir,
        qr/^\Q$config_dir\E.*assets.*complex_modifications$/,
        'Complex mods dir is properly nested under config dir'
    );
};

db("### KARABINER PATHS TESTS COMPLETE ###");
done_testing();