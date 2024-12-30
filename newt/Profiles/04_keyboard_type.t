# 04_keyboard_type.t - Test keyboard type configuration in profiles
use strict;
use warnings;
use Test::Most 'die';
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use KarabinerGenerator::Config qw(get_path);
use KarabinerGenerator::Init qw(init db);
use KarabinerGenerator::JSONHandler qw(read_json_file);
use KarabinerGenerator::TestEnvironment::Loader qw(
    load_project_defaults
    load_karabiner_defaults
    load_test_fixtures
);
use KarabinerGenerator::Profiles qw(install_profile);
use YAML::XS qw(LoadFile);

# Initialize test environment
init();
load_project_defaults();
load_karabiner_defaults();
load_test_fixtures();

# Debug: Check if config file exists and can be loaded
my $config_path = get_path('profile_config_yaml');
db("Profile config path: $config_path");
db("Config file exists: " . (-f $config_path ? "YES" : "NO"));

if (-f $config_path) {
    my $yaml = eval { LoadFile($config_path) };
    if ($@) {
        db("Error loading YAML: $@");
    } else {
        use Data::Dumper;
        db("Loaded YAML content:");
        db(Dumper($yaml));
    }
}

# Debug: Check karabiner.json
my $karabiner_json = get_path('karabiner_json');
db("Karabiner.json path: $karabiner_json");
db("Karabiner.json exists: " . (-f $karabiner_json ? "YES" : "NO"));

# Test profile with no keyboard setting
subtest 'No keyboard type specified' => sub {
    my $result = install_profile('NoKeyboard');
    db("install_profile result: " . ($result ? "SUCCESS" : "FAILURE"));
    
    my $config = read_json_file($karabiner_json);
    db("Current profiles in karabiner.json:");
    db(Dumper($config->{profiles}));
    
    my ($profile) = grep { $_->{name} eq 'GJ-NoKeyboard' } @{$config->{profiles}};
    ok($profile, 'Profile was created');
    ok(!exists $profile->{virtual_hid_keyboard}, 
       'No virtual_hid_keyboard when keyboard type not specified');
};

# Rest of the test remains the same...

# Test each valid keyboard type
for my $test_case (
    { name => 'Default', type => 'ansi' },
    { name => 'ISOKeyboard', type => 'iso' },
    { name => 'JISKeyboard', type => 'jis' },
    { name => 'InvalidKeyboard', type => 'invalid', expected => 'ansi' }
) {
    subtest "Keyboard type: $test_case->{name}" => sub {
        my $karabiner_json = get_path('karabiner_json');
        install_profile($test_case->{name});
        my $config = read_json_file($karabiner_json);
        
        my ($profile) = grep { $_->{name} eq "GJ-$test_case->{name}" } @{$config->{profiles}};
        ok($profile, 'Profile was created');
        is($profile->{virtual_hid_keyboard}{keyboard_type_v2}, 
           $test_case->{expected} // $test_case->{type},
           "Keyboard type set correctly");
    };
}

done_testing();