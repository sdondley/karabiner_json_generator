# 02_reset.t - Test karabiner.json reset functionality
use strict;
use warnings;
use Test::Most;
use FindBin qw($RealBin);
use lib "$FindBin::Bin/../../../lib";
use lib "$FindBin::Bin/../../ManifestTest";
use KarabinerGenerator::Init qw(init db);
use KarabinerGenerator::Config qw(get_path);
use KarabinerGenerator::JSONHandler qw(read_json_file);
use KarabinerGenerator::TestEnvironment::Loader qw(
    load_karabiner_defaults
    load_test_fixtures
);
use KarabinerGenerator::KarabinerInstallation::JSONFile qw(reset_karabiner_json);

# Initialize test environment
init();
db("\n### Starting test - after init() ###");

load_karabiner_defaults();
db("After load_karabiner_defaults()");

load_test_fixtures();
db("After load_test_fixtures()");

subtest "successful reset" => sub {
    plan tests => 4;  # Changed from 3 to 4 to include the subtest
    
    db("\n### Starting successful reset subtest ###");
    my $karabiner_dir = get_path('karabiner_dir');
    db("karabiner_dir: $karabiner_dir");
    my $karabiner_json = get_path('karabiner_json');
    db("karabiner_json path: $karabiner_json");
    db("karabiner_json exists? " . (-f $karabiner_json ? "YES" : "NO"));
    
    ok(reset_karabiner_json(), "Reset operation succeeded");
    db("After reset_karabiner_json() call");

    my $config = read_json_file($karabiner_json);
    db("After reading json file");
    ok($config->{profiles}, "Config has profiles array");
    is(scalar @{$config->{profiles}}, 1, "Config has exactly one profile");
    
    my $profile = $config->{profiles}[0];
    subtest "default profile structure" => sub {
        plan tests => 6;
        is($profile->{name}, "Default", "Profile has correct name");
        is_deeply($profile->{complex_modifications}, { rules => [] }, "Complex modifications is empty");
        is_deeply($profile->{simple_modifications}, [], "Simple modifications is empty");
        is_deeply($profile->{fn_function_keys}, [], "Function keys are empty");
        is_deeply($profile->{devices}, [], "Devices are empty");
        is($profile->{selected}, JSON::true, "Profile is selected");
    };
};

done_testing();