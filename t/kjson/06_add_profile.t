use strict;
use warnings;
use Test::Most tests => 5, 'die';
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use File::Temp qw(tempdir);
use JSON;

# Import the config module with required functions
use KarabinerGenerator::Config qw(mode get_path);

# Ensure we're in test mode
mode('test');

# Test module loading and import the new function
use_ok('KarabinerGenerator::KarabinerJsonFile', qw(
    read_karabiner_json 
    write_karabiner_json 
    get_profile_names
    add_profile
));

# Get path to test Karabiner.json fixture
my $fixture_path = get_path('karabiner_json');

# Test adding a new profile
subtest 'Add new profile' => sub {
    plan tests => 4;
    
    my $config = read_karabiner_json($fixture_path);
    my $initial_profile_count = scalar @{$config->{profiles}};
    
    ok(add_profile($config, "NewTestProfile"), 
       "Successfully added new profile");
       
    is(scalar @{$config->{profiles}}, $initial_profile_count + 1,
       "Profile count increased by one");
       
    my $new_profile = $config->{profiles}[-1];
    is($new_profile->{name}, "NewTestProfile",
       "New profile has correct name");
       
    ok(exists $new_profile->{complex_modifications} &&
       ref($new_profile->{complex_modifications}) eq 'HASH' &&
       exists $new_profile->{complex_modifications}{rules},
       "New profile has correct structure");
};

# Test attempting to add duplicate profile
subtest 'Prevent duplicate profiles' => sub {
    plan tests => 2;
    
    my $config = read_karabiner_json($fixture_path);
    my $initial_profile_count = scalar @{$config->{profiles}};
    
    ok(!add_profile($config, "Default"),
       "Adding duplicate profile returns false");
       
    is(scalar @{$config->{profiles}}, $initial_profile_count,
       "Profile count unchanged after duplicate attempt");
};

# Test adding profile with invalid names
subtest 'Invalid profile names' => sub {
    plan tests => 4;
    
    my $config = read_karabiner_json($fixture_path);
    
    throws_ok(
        sub { add_profile($config, "") },
        qr/Profile name not provided/,
        "Empty profile name rejected"
    );
    
    throws_ok(
        sub { add_profile($config, undef) },
        qr/Profile name not provided/,
        "Undefined profile name rejected"
    );
    
    throws_ok(
        sub { add_profile(undef, "ValidName") },
        qr/Configuration not provided/,
        "Missing config rejected"
    );
    
    my $initial_profile_count = scalar @{$config->{profiles}};
    is(scalar @{$config->{profiles}}, $initial_profile_count,
       "Profile count unchanged after invalid attempts");
};

# Test persistence of added profile
subtest 'Profile persistence' => sub {
    plan tests => 3;
    
    my $config = read_karabiner_json($fixture_path);
    ok(add_profile($config, "PersistenceTest"),
       "Added test profile");
    
    # Use generated_json_dir from Config.pm for test output
    my $test_output = get_path('generated_json_dir') . "/test_persistence.json";
    ok(write_karabiner_json($config, $test_output),
       "Wrote config with new profile");
    
    my $read_config = read_karabiner_json($test_output);
    my $profiles = get_profile_names($read_config);
    ok(grep({ $_ eq "PersistenceTest" } @$profiles),
       "New profile persists after write and read");
};