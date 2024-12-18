# t/profiles/06_profile_generation.t - Test profile generation functionality

use strict;
use warnings;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use File::Spec;
use File::Path qw(make_path);

use KarabinerGenerator::Config qw(get_path mode reset_test_environment);
use KarabinerGenerator::Profiles qw(
    generate_config
    has_profile_config
    get_profile_names
    bundle_profile
    install_bundled_profile
);

# Force test mode and clean environment
mode('test');
reset_test_environment();

# Test profile config generation
subtest 'Profile config generation' => sub {
    ok(!has_profile_config(), 'No initial profile config');
    ok(generate_config(), 'Generate default profile config');
    ok(has_profile_config(), 'Profile config exists after generation');
    
    my $config_path = get_path('profile_config_yaml');
    ok(-f $config_path, 'Config file exists at expected path');
};

# Test profile name retrieval
subtest 'Profile name retrieval' => sub {
    my @profile_names = get_profile_names();
    ok(@profile_names, 'Got profile names');
    ok((grep { $_ eq 'Default' } @profile_names), 'Default profile exists');
};

# Test profile bundling
subtest 'Profile bundling' => sub {
    my $profiles_dir = get_path('generated_profiles_dir');
    make_path($profiles_dir) unless -d $profiles_dir;
    
    # Bundle default profile
    ok(bundle_profile('Default'), 'Bundle Default profile');
    
    # Check if file was created
    my $profile_file = File::Spec->catfile($profiles_dir, 'GJ-Default.json');
    ok(-f $profile_file, 'Profile JSON file was created');
    
    # Basic content validation
    open my $fh, '<', $profile_file or die "Cannot open profile file: $!";
    my $content = do { local $/; <$fh> };
    close $fh;
    
    like($content, qr/"title"/, 'Profile JSON contains title');
    like($content, qr/"rules"/, 'Profile JSON contains rules array');
};

# Test profile installation
subtest 'Profile installation' => sub {
    my $complex_mods_dir = get_path('complex_mods_dir');
    make_path($complex_mods_dir) unless -d $complex_mods_dir;
    
    ok(install_bundled_profile('Default'), 'Install Default profile');
    
    my $installed_file = File::Spec->catfile($complex_mods_dir, 'GJ-Default.json');
    ok(-f $installed_file, 'Profile was installed to complex modifications');
};

# Test multiple profile handling
subtest 'Multiple profile handling' => sub {
    # Generate a config with multiple profiles
    my $config_path = get_path('profile_config_yaml');
    open my $fh, '>', $config_path or die "Cannot open config: $!";
    print $fh <<'EOT';
common:
  rules:
    - ctrl-esc
profiles:
  Default:
    title: Default Profile
    common: true
  Gaming:
    title: Gaming Profile
    common: false
    rules:
      - test
EOT
    close $fh;

    # Test retrieval
    my @profiles = get_profile_names();
    is(scalar(@profiles), 2, 'Got correct number of profiles');
    ok((grep { $_ eq 'Gaming' } @profiles), 'Gaming profile exists');
    
    # Test bundling
    ok(bundle_profile('Gaming'), 'Bundle Gaming profile');
    ok(install_bundled_profile('Gaming'), 'Install Gaming profile');
    
    my $gaming_file = File::Spec->catfile(get_path('complex_mods_dir'), 'GJ-Gaming.json');
    ok(-f $gaming_file, 'Gaming profile was installed');
};

# Add this test case to t/profiles/06_profile_generation.t right after 'Multiple profile handling' subtest:

subtest 'Profile directory creation' => sub {
    # Get all relevant directories
    my $json_dir = get_path('generated_json_dir');
    my $profiles_dir = get_path('generated_profiles_dir');
    my $complex_mods_dir = get_path('complex_mods_dir');
    
    # Ensure directories get created
    make_path($json_dir) unless -d $json_dir;
    make_path($profiles_dir) unless -d $profiles_dir;
    make_path($complex_mods_dir) unless -d $complex_mods_dir;
    
    # Create a basic test rule
    my $test_rule = File::Spec->catfile($json_dir, 'ctrl-esc.json');
    open my $fh, '>', $test_rule or die "Cannot create test rule: $!";
    print $fh '{"rules":[{"description":"Test rule"}]}';
    close $fh;
    
    # Generate and validate config
    ok(generate_config(), 'Generate basic config');
    ok(has_profile_config(), 'Config file exists');
    
    # Test profiles directory creation during bundling
    my $profile_name = 'Default';
    ok(bundle_profile($profile_name), 'Bundle default profile');
    ok(-d $profiles_dir, 'Profiles directory was created');
    
    my $bundle_file = File::Spec->catfile($profiles_dir, "GJ-$profile_name.json");
    ok(-f $bundle_file, 'Profile bundle was created');
    
    ok(install_bundled_profile($profile_name), 'Install default profile');
    my $installed_file = File::Spec->catfile($complex_mods_dir, "GJ-$profile_name.json");
    ok(-f $installed_file, 'Profile was installed to complex mods directory');
};



done_testing;