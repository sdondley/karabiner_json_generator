use strict;
use warnings;
use Test::Most 'die';
use Test::Deep;
use File::Temp qw(tempdir);
use File::Spec;
use File::Path qw(make_path);
use FindBin qw($RealBin);
use Cwd qw(abs_path getcwd);
use lib "$RealBin/../lib";

use KarabinerGenerator::Config qw(load_config get_path mode reset_test_environment);

# Reset test environment before starting
reset_test_environment();

# Test mode function
subtest 'Mode Function' => sub {
    plan tests => 4;

    # Test initial mode (should be test since we're running under harness)
    is(mode(), 'test', 'Initial mode is test under harness');

    # Test setting mode
    is(mode('prod'), 'prod', 'Can set mode to prod');
    is(mode('test'), 'test', 'Can set mode to test');

    # Test invalid mode
    eval { mode('invalid') };
    like($@, qr/Invalid mode/, 'Invalid mode throws error');
};

# Test path retrieval in test mode
subtest 'Test Mode Paths' => sub {
    plan tests => 9;

    mode('test');

    # Test each path type
    ok(get_path('cli_path'), 'Can get cli_path');
    like(get_path('cli_path'), qr/karabiner_cli$/, 'CLI path looks correct');

    my $config_dir = get_path('config_dir');
    ok(-d $config_dir, 'Config directory exists');
    like($config_dir, qr/\.tmp_dir.+mockups.+karabiner$/, 'Config dir is in mockups/karabiner');

    ok(-d get_path('complex_mods_dir'), 'Complex mods directory exists');
    ok(-d get_path('templates_dir'), 'Templates directory exists');
    ok(-d get_path('generated_json_dir'), 'Generated JSON directory exists');

    # All paths should be absolute
    like(get_path('templates_dir'), qr{^/}, 'Templates path is absolute');
    like(get_path('generated_json_dir'), qr{^/}, 'Generated JSON path is absolute');
};

# Test invalid path retrieval
subtest 'Invalid Path Requests' => sub {
    plan tests => 1;

    eval { get_path('nonexistent_path') };
    like($@, qr/Unknown resource/, 'Invalid path request throws error');
};

# Test production paths
subtest 'Production Mode Paths' => sub {
    plan tests => 7;

    mode('prod');
    local $ENV{HOME} = '/Users/testuser';

    # Test absolute paths
    like(get_path('config_dir'), qr{^/}, 'Config dir is absolute');
    like(get_path('complex_mods_dir'), qr{^/}, 'Complex mods dir is absolute');
    like(get_path('templates_dir'), qr{^/}, 'Templates dir is absolute');
    like(get_path('generated_json_dir'), qr{^/}, 'Generated JSON dir is absolute');

    # Test expected locations
    like(get_path('config_dir'), qr{\.config/karabiner$}, 'Config dir in correct location');
    like(get_path('complex_mods_dir'), qr{complex_modifications$}, 'Complex mods in correct location');
    like(get_path('cli_path'), qr/karabiner_cli$/, 'CLI path in correct location');
};

# Test config loading and overrides
subtest 'Config Loading and Overrides' => sub {
    plan tests => 4;

    mode('test');
    my $config = load_config();

    ok($config, 'Config loaded successfully');
    ok($config->{global}, 'Global config section exists');
    ok($config->{global}{karabiner}, 'Karabiner section exists in global config');

    # Test that global config paths override defaults
    # This assumes your fixture's global_config.yaml has some path overrides
    if ($config->{global}{karabiner}{complex_mods_dir}) {
        my $override_path = get_path('complex_mods_dir');
        like($override_path, qr{^/}, 'Overridden path is absolute');
    } else {
        pass('No path overrides in test config');
    }
};

# Test path consistency
subtest 'Path Consistency' => sub {
    plan tests => 3;

    mode('test');
    my $path1 = get_path('config_dir');
    my $path2 = get_path('config_dir');

    is($path1, $path2, 'Same path returned on multiple calls');

    mode('prod');
    my $prod_path = get_path('config_dir');
    isnt($prod_path, $path1, 'Different paths for different modes');

    mode('test');
    is(get_path('config_dir'), $path1, 'Path restored when mode switched back');
};

done_testing();