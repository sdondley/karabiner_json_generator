# newt/Config/04_yaml_config.t
use strict;
use warnings;
use Test::Most 'die';
use Test::Exception;
use Test::Warn;
use FindBin;
use File::Path qw(rmtree);
use lib "$FindBin::Bin/../../lib";
use lib "$FindBin::Bin/../../ManifestTest";

use KarabinerGenerator::Init qw(init is_test_mode db);
use KarabinerGenerator::Config qw(get_path load_config);
use KarabinerGenerator::TestEnvironment qw(setup_test_environment);
use KarabinerGenerator::TestEnvironment::Loader qw(
    load_project_defaults
    load_karabiner_defaults
);

db("### STARTING YAML CONFIG TESTS ###");

# Initialize FIRST
lives_ok(
    sub { init() },
    'Environment initialization completed'
);

# Ensure we're in test mode
ok(is_test_mode(), 'Running in test mode');

# Test with no config files
subtest 'No config files' => sub {
    plan tests => 2;
    
    my $config;
    warnings_like { 
        $config = load_config() 
    } [qr/No template config found at .+template_config\.yaml/],
    'Expected warning about missing template config';
    
    is_deeply(
        $config,
        { global => {}, profiles => {} },
        'Returns empty config structure when no files exist'
    );
};

# Test with only project defaults loaded
subtest 'Project defaults only' => sub {
    plan tests => 4;
    
    lives_ok(
        sub { load_project_defaults() },
        'Project defaults loaded'
    );
    
    my $config = load_config();
    db("Dumping config structure:");
    use Data::Dumper;
    local $Data::Dumper::Sortkeys = 1;
    db(Dumper($config));
    ok(exists $config->{global}, 'Global config loaded'); 
    ok(exists $config->{global}{karabiner}, 'Karabiner config exists');
    like($config->{global}{karabiner}{config_dir}, qr/\.config\/karabiner$/, 'Config dir path correct');
};

# Test with all config files
subtest 'All config files' => sub {
    plan tests => 5;
    
    lives_ok(
        sub { 
            load_project_defaults();
            load_karabiner_defaults();
        },
        'Test fixtures loaded successfully'
    );

    my $config = load_config();
    ok(exists $config->{global}, 'Global config section exists');
    ok(exists $config->{profiles}, 'Profiles section exists');
    ok(exists $config->{ruleset}, 'Ruleset section exists');
    like($config->{ruleset}{shell_command}, qr/master\.sh$/, 'Template config loaded correctly');
};

END {
    my $project_dir = get_path('project_dir');
    rmtree($project_dir) if -d $project_dir;
}

db("### YAML CONFIG TESTS COMPLETE ###");
done_testing();