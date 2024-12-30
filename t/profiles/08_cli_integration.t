# t/profiles/08_cli_integration.t
use strict;
use warnings;
use Test::Most;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use File::Copy qw(copy);
use File::Path qw(make_path remove_tree);
use File::Spec;
use JSON;

use KarabinerGenerator::Config qw(get_path reset_test_environment);
use KarabinerGenerator::Profiles qw(
    PROFILE_PREFIX 
    generate_config 
    bundle_profile 
    install_bundled_profile
    update_karabiner_profiles
);

# Reset environment
reset_test_environment();

# Get necessary paths
my $json_dir = get_path('generated_json_dir');
my $profiles_dir = get_path('generated_profiles_dir');
my $complex_mods_dir = get_path('complex_mods_dir');
my $karabiner_json = get_path('karabiner_json');
my $profile_config = get_path('profile_config_yaml');

# Test setup 
subtest 'Setup' => sub {
    plan tests => 4;
    
    # Setup directories
    for my $dir ($json_dir, $profiles_dir, $complex_mods_dir) {
        remove_tree($dir) if -d $dir;
        make_path($dir);
    }
    
    # Create test rule
    my $rule = {
        title => "Test Rule",
        rules => [{ 
            description => "Test Rule", 
            manipulators => []
        }]
    };

    open my $fh, '>', "$json_dir/test1.json" or die $!;
    print $fh encode_json($rule);
    close $fh;
    ok(-f "$json_dir/test1.json", "Created test1.json");

    # Create karabiner.json with existing profiles
    my $karabiner = {
        global => {
            show_in_menu_bar => JSON::true
        },
        profiles => [
            {
                name => "Existing Profile 1",
                selected => JSON::true,
                complex_modifications => { rules => [] }
            },
            {
                name => "Existing Profile 2",
                selected => JSON::false,
                complex_modifications => { rules => [] }
            }
        ]
    };
    
    open $fh, '>', $karabiner_json or die $!;
    print $fh encode_json($karabiner);
    close $fh;
    ok(-f $karabiner_json, "Created karabiner.json with existing profiles");

    # Create profile config
    open $fh, '>', $profile_config or die $!;
    print $fh <<'EOT';
common:
  rules: []
profiles:
  Default:
    title: Default Profile
    rules:
      - test1
EOT
    close $fh;
    ok(-f $profile_config, "Created profile config");

    # Create directories
    ok(-d $complex_mods_dir, "Complex mods directory exists");
};

# Test profile creation and installation
subtest 'Profile Creation and Installation' => sub {
    plan tests => 5;

    # Bundle the profile
    ok(bundle_profile('Default'), "Bundle profile created");
    ok(-f "$profiles_dir/GJ-Default.json", "Bundle file exists");

    # Install the bundle
    ok(install_bundled_profile('Default'), "Profile installed");
    ok(-f "$complex_mods_dir/GJ-Default.json", "Installed file exists");

    # Update karabiner.json
    ok(update_karabiner_profiles(), "Updated karabiner.json");
};

# Verify final state
subtest 'Final State' => sub {
    plan tests => 5;

    # Check karabiner.json
    open my $fh, '<', $karabiner_json or die "Can't read $karabiner_json: $!";
    my $config = decode_json(do { local $/; <$fh> });
    close $fh;

    my @profiles = map { $_->{name} } @{$config->{profiles}};
    diag("Found profiles: @profiles");

    is(scalar(@{$config->{profiles}}), 3, "Three profiles exist (2 existing + 1 new)");
    
    # Check existing profiles were preserved
    my %profile_map = map { $_->{name} => $_ } @{$config->{profiles}};
    ok(exists $profile_map{"Existing Profile 1"}, "Existing profile 1 preserved");
    ok(exists $profile_map{"Existing Profile 2"}, "Existing profile 2 preserved");
    ok(exists $profile_map{"GJ-Default"}, "New GJ-Default profile exists");
    
    # Verify selected state preserved
    is($profile_map{"Existing Profile 1"}{selected}, JSON::true, "Selected state preserved");
};

done_testing;