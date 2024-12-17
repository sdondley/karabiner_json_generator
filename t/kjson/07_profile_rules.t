use strict;
use warnings;
use Test::Most tests => 4, 'die';
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use JSON;

# Import the config module with required functions
use KarabinerGenerator::Config qw(mode get_path);


# Test module loading
use_ok('KarabinerGenerator::KarabinerJsonFile', qw(
    read_karabiner_json
    write_karabiner_json
    get_profile_names
    get_current_profile_rules
    clear_profile_rules
    add_profile_rules
));

# Get karabiner.json path
my $karabiner_json = get_path('karabiner_json');

# Mock rules for testing
my $mock_rules = [
    {
        description => "Test Rule 1",
        manipulators => [],
        enabled => JSON::true
    },
    {
        description => "Test Rule 2",
        manipulators => [],
        enabled => JSON::true
    }
];

# Test clearing rules
subtest 'Clear rules' => sub {
    plan tests => 3;
    
    my $config = read_karabiner_json($karabiner_json);
    my $test_output = get_path('generated_json_dir') . "/test_clear.json";
    
    ok(clear_profile_rules($config, 'Default'), 'Cleared rules from Default profile');
    ok(write_karabiner_json($config, $test_output), 'Wrote config after clearing');
    
    my $updated_config = read_karabiner_json($test_output);
    my $rules = get_current_profile_rules($updated_config, 'Default');
    is(scalar(@$rules), 0, 'Profile has no rules after clearing');
};

# Test adding rules
subtest 'Add rules' => sub {
    plan tests => 4;
    
    my $config = read_karabiner_json($karabiner_json);
    my $test_output = get_path('generated_json_dir') . "/test_add.json";
    
    ok(clear_profile_rules($config, 'Default'), 'Cleared rules from Default profile');
    ok(add_profile_rules($config, 'Default', $mock_rules), 'Added new rules to Default profile');
    ok(write_karabiner_json($config, $test_output), 'Wrote config after adding rules');
    
    my $updated_config = read_karabiner_json($test_output);
    my $rules = get_current_profile_rules($updated_config, 'Default');
    is(scalar(@$rules), 2, 'Profile has two rules after adding');
};

# Test error conditions
subtest 'Error conditions' => sub {
    plan tests => 4;
    
    my $config = read_karabiner_json($karabiner_json);
    
    # Test with non-existent profile
    ok(!clear_profile_rules($config, 'NonExistentProfile'), 
       'clear_profile_rules fails with invalid profile');
       
    ok(!add_profile_rules($config, 'NonExistentProfile', $mock_rules),
       'add_profile_rules fails with invalid profile');
       
    # Changed from throws_ok to ok with negation
    ok(!add_profile_rules($config, 'Default', undef),
       'add_profile_rules fails with undefined rules');
    
    ok(!add_profile_rules($config, 'Default', "not an array"),
       'add_profile_rules fails with non-array rules');
};