use strict;
use warnings;
use Test::Most tests => 5, 'die';
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use File::Spec;
use File::Basename qw(dirname);
use JSON;

# Test module loading
use_ok('KarabinerGenerator::KarabinerJsonFile', qw(
    read_karabiner_json 
    write_karabiner_json 
    get_profile_names 
    get_current_profile_rules
));
use KarabinerGenerator::Config qw(mode get_path reset_test_environment);

# Ensure clean test environment
BEGIN {
    mode('test');
    reset_test_environment();
}

# Clean up after all tests
END {
    reset_test_environment();
}

# Get paths from Config
my $karabiner_json = get_path('karabiner_json');
my $generated_json_dir = get_path('generated_json_dir');
my $test_dir = dirname($generated_json_dir);

# Test rules without enabled property
subtest 'Rules without enabled property' => sub {
    plan tests => 5;
    
    my $config = read_karabiner_json($karabiner_json);
    my $rules = get_current_profile_rules($config, 'Default');
    
    # Verify rule exists without enabled property
    ok($rules->[0], 'Found rule');
    ok(!exists $rules->[0]{enabled}, 'Rule has no enabled property initially');
    
    # Add enabled property
    $rules->[0]{enabled} = JSON::true;
    
    # Write and read back
    my $test_output = File::Spec->catfile($generated_json_dir, 'test_add_enabled.json');
    ok(index($test_output, $test_dir) == 0, 'Output file is within test directory');
    ok(write_karabiner_json($config, $test_output), 'Wrote config with new enabled property');
    
    # Delete enabled property
    delete $rules->[0]{enabled};
    ok(write_karabiner_json($config, $test_output), 'Wrote config after removing enabled property');
};

# Test enabling/disabling rules
subtest 'Enable/disable rule' => sub {
    plan tests => 6;
    
    my $config = read_karabiner_json($karabiner_json);
    ok($config, 'Config loaded successfully');
    
    # Get Default profile's rules
    my $rules = get_current_profile_rules($config, 'Default');
    is(scalar(@$rules), 1, 'Found one rule in Default profile');
    
    # Enable the rule explicitly
    $rules->[0]{enabled} = JSON::true;
    
    # Write config back
    my $test_output = File::Spec->catfile($generated_json_dir, 'test_enable.json');
    ok(index($test_output, $test_dir) == 0, 'Output file is within test directory');
    ok(write_karabiner_json($config, $test_output), 'Wrote config with enabled rule');
    
    # Read it back and verify
    my $updated_config = read_karabiner_json($test_output);
    my $updated_rules = get_current_profile_rules($updated_config, 'Default');
    is($updated_rules->[0]{enabled}, JSON::true, 'Rule is enabled in saved config');
    
    # Disable the rule
    $rules->[0]{enabled} = JSON::false;
    ok(write_karabiner_json($config, $test_output), 'Wrote config with disabled rule');
};

# Test multiple rules enable/disable states
subtest 'Multiple rules enable/disable' => sub {
    plan tests => 6;
    
    my $config = read_karabiner_json($karabiner_json);
    
    # Add a second rule to Default profile (without enabled property)
    my $default_profile = $config->{profiles}[0];
    push @{$default_profile->{complex_modifications}{rules}}, {
        description => "Test Rule 2",
        manipulators => []
    };
    
    # Add a third rule (with enabled property)
    push @{$default_profile->{complex_modifications}{rules}}, {
        description => "Test Rule 3",
        manipulators => [],
        enabled => JSON::true
    };
    
    # Set different states for rules
    $default_profile->{complex_modifications}{rules}[0]{enabled} = JSON::false;
    # Rule 2 intentionally left without enabled property
    
    # Write and verify
    my $test_output = File::Spec->catfile($generated_json_dir, 'test_multiple.json');
    ok(index($test_output, $test_dir) == 0, 'Output file is within test directory');
    ok(write_karabiner_json($config, $test_output), 'Wrote config with multiple rules');
    
    # Read back and verify states
    my $updated_config = read_karabiner_json($test_output);
    my $rules = get_current_profile_rules($updated_config, 'Default');
    
    is(scalar(@$rules), 3, 'Found three rules');
    is($rules->[0]{enabled}, JSON::false, 'First rule is explicitly disabled');
    ok(!exists $rules->[1]{enabled}, 'Second rule has no enabled property');
    is($rules->[2]{enabled}, JSON::true, 'Third rule is explicitly enabled');
};

# Test invalid enable/disable values
subtest 'Invalid enable values' => sub {
    plan tests => 3;
    
    my $config = read_karabiner_json($karabiner_json);
    my $rules = get_current_profile_rules($config, 'Default');
    
    # Try setting non-boolean values
    $rules->[0]{enabled} = "true";  # String instead of boolean
    
    my $test_output = File::Spec->catfile($generated_json_dir, 'test_invalid.json');
    ok(index($test_output, $test_dir) == 0, 'Output file is within test directory');
    
    # This should now fail due to our stricter validation
    # Temporarily suppress the expected warning
    {
        local $SIG{__WARN__} = sub {
            my $msg = shift;
            die $msg unless $msg =~ /Invalid 'enabled' value found/;
        };
        ok(!write_karabiner_json($config, $test_output), 
           'Writing config with string boolean should fail');
    }
    
    # Verify the file wasn't created
    ok(!-f $test_output || -z $test_output, 
       'Invalid config file should not be written');
};