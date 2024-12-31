# newt/KarabinerInstallation/JSONFile/01_jsonfile_basic.t
use strict;
use warnings;
use Test::Most 'die';

use KarabinerGenerator::Init qw(init db dbd);
use KarabinerGenerator::Config qw(get_path);
use KarabinerGenerator::JSONHandler qw(read_json_file write_json_file);
use KarabinerGenerator::TestEnvironment::Loader qw(load_test_fixtures
load_karabiner_defaults);
use KarabinerGenerator::KarabinerInstallation::JSONFile qw(
    validate_karabiner_json
    get_profile_names
    get_current_profile
    add_profile
    clear_profile_rules
    add_profile_rules
    update_generated_rules
);

init();
db("\n### DEBUG PATHS ###");
db("fixtures_karabiner_defaults_dir: " . get_path('fixtures_karabiner_defaults_dir'));
db("karabiner_dir: " . get_path('karabiner_dir'));
load_karabiner_defaults();

my $karabiner_json = get_path('karabiner_json');

subtest 'validate_karabiner_json' => sub {
    ok(validate_karabiner_json($karabiner_json), 'Default config validates');
};

subtest 'profile_operations' => sub {
    my $config = read_json_file($karabiner_json);
    ok(add_profile($config, "Test Profile"), 'Add new profile');
    ok(!add_profile($config, "Test Profile"), 'Reject duplicate');
    ok(clear_profile_rules($config, "Test Profile"), 'Clear profile rules');
};

done_testing();