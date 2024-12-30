# 03_profile_installation.t
use strict;
use warnings;
use Test::Most 'die';
use FindBin;
use lib "$FindBin::Bin/../../lib";

use KarabinerGenerator::Init qw(init db dbd);
use KarabinerGenerator::TestEnvironment::Loader qw(
    load_project_defaults 
    load_karabiner_defaults
    load_test_fixtures
);
use KarabinerGenerator::Template qw(process_templates);
use KarabinerGenerator::Config qw(get_path load_config);
use KarabinerGenerator::JSONHandler qw(read_json_file write_json_file);
use KarabinerGenerator::KarabinerInstallation::JSONFile qw(
    validate_karabiner_json
    get_profile_names
    get_current_profile
    add_profile
    clear_profile_rules
    add_profile_rules
    update_generated_rules
);

db("\n### Starting Profile Installation Test ###");
init();
load_project_defaults();
load_karabiner_defaults();
load_test_fixtures();

# Load initial karabiner.json state
my $karabiner_json = get_path('karabiner_json');
db("Karabiner JSON path: $karabiner_json");
ok(validate_karabiner_json($karabiner_json), "Initial karabiner.json is valid");

# Process templates to generate rule files
my $config = load_config();
process_templates($config);

# Test profile operations
subtest "Profile operations" => sub {
    db("\nReading initial karabiner.json");
    my $config = eval { read_json_file($karabiner_json) };
    if ($@) {
        db("Error reading JSON: $@");
    }
    db("\nInitial karabiner.json content:");
    if ($config) {
        db("Raw config: " . ($config ? "defined" : "undefined"));
        use Data::Dumper;
        local $Data::Dumper::Maxdepth = 3;
        local $Data::Dumper::Sortkeys = 1;
        db(Dumper($config));
    } else {
        db("Config is undefined!")
    }
    
    # Test adding a new profile
    ok(add_profile($config, 'Test Profile'), "Added new profile");
    
    db("\nAfter adding profile:");
    dbd($config);
    
    # Clear rules and verify
    ok(clear_profile_rules($config, 'Test Profile'), "Cleared profile rules");
    my ($test_profile) = grep { $_->{name} eq 'Test Profile' } @{$config->{profiles}};
    is_deeply($test_profile->{complex_modifications}{rules}, [], "Rules array is empty");
    
    # Add rules to profile
    my $test_rules = [{
        description => "Test Rule",
        manipulators => [{
            type => "basic",
            from => { key_code => "z" },
            to => [{ key_code => "a" }]
        }]
    }];
    ok(add_profile_rules($config, 'Test Profile', $test_rules), "Added rules to profile");
    
    db("\nAfter adding rules:");
    dbd($config);
    
    # Write changes
    ok(write_json_file($karabiner_json, $config), "Wrote changes to karabiner.json");
    ok(validate_karabiner_json($karabiner_json), "Modified karabiner.json is valid");
};

# Test update_generated_rules
subtest "Generated rules" => sub {
    my $config = read_json_file($karabiner_json);
    my $complex_mods_dir = get_path('karabiner_complex_mods_dir');
    db("\nComplex mods directory: $complex_mods_dir");
    
    ok(update_generated_rules($config, $complex_mods_dir), "Updated generated rules");
    
    # Verify Generated JSON profile exists with rules
    my ($gen_profile) = grep { $_->{name} eq 'Generated JSON' } @{$config->{profiles}};
    ok($gen_profile, "Generated JSON profile exists");
    ok(ref($gen_profile->{complex_modifications}{rules}) eq 'ARRAY', "Has rules array");
    
    write_json_file($karabiner_json, $config);
    ok(validate_karabiner_json($karabiner_json), "Final karabiner.json is valid");
};

# Test profile listing and current profile
db("\nTesting profile list");
my $profiles_result = get_profile_names($karabiner_json);
db("Profile names result:");
dbd($profiles_result);

my @profiles = @{$profiles_result};
db("Profiles found: " . join(", ", @profiles));

ok(grep({ $_ eq 'Test Profile' } @profiles), "New profile appears in profile list");

my $current = get_current_profile($karabiner_json);
db("Current profile: " . ($current // "undef"));
ok($current, "Can get current profile");

done_testing();