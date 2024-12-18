# t/profiles/01_basic.t - Basic profile functionality tests

use strict;
use warnings;
use Test::Most tests => 11;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use File::Spec;
use File::Path qw(make_path remove_tree);

# Set test mode before loading config
use KarabinerGenerator::Config qw(mode get_path reset_test_environment);

BEGIN {
    mode('test');
    reset_test_environment();
}

# Test module loading with explicit import of PROFILE_PREFIX
use KarabinerGenerator::Profiles qw(PROFILE_PREFIX);
use_ok('KarabinerGenerator::Profiles')
    or BAIL_OUT("Failed to load KarabinerGenerator::Profiles module");

# Test profile_config.yaml path is available
my $profile_config = get_path('profile_config_yaml');
ok(defined $profile_config, 'profile_config_yaml path is defined');
like($profile_config, qr/profile_config\.yaml$/, 'profile_config_yaml path has correct filename');

# Test profile prefix constant
ok(PROFILE_PREFIX, 'PROFILE_PREFIX is defined');
is(PROFILE_PREFIX, 'GJ', 'PROFILE_PREFIX is set to GJ');
like(PROFILE_PREFIX . ' - Default', qr/^GJ - /, 'Profile prefix works in string context');

# Test generated_profiles_dir path
my $profiles_dir = get_path('generated_profiles_dir');
ok(defined $profiles_dir, 'generated_profiles_dir path is defined');
like($profiles_dir, qr/generated_profiles$/, 'generated_profiles_dir has correct directory name');

# Test directory is at same level as generated_json
my $json_dir = get_path('generated_json_dir');
my (undef, $json_parent_dir) = File::Spec->splitpath($json_dir);
my (undef, $profiles_parent_dir) = File::Spec->splitpath($profiles_dir);
is($profiles_parent_dir, $json_parent_dir, 'generated_profiles_dir is at same level as generated_json_dir');

# Clean up and test directory handling
remove_tree($profiles_dir) if -d $profiles_dir;  # Ensure clean state
ok(!-d $profiles_dir, 'Directory does not exist initially');
make_path($profiles_dir);
ok(-d $profiles_dir, 'Directory can be created');

# Clean up after test
remove_tree($profiles_dir);