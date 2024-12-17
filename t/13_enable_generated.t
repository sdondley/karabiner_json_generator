use strict;
use warnings;
use Test::Most tests => 6, 'die';
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::Spec;
use FindBin qw($RealBin);
use Capture::Tiny qw(capture);
use lib "$RealBin/../lib";
use KarabinerGenerator::Config qw(get_path mode);

BEGIN { 
    $ENV{TEST_MODE} = 1;
    $ENV{QUIET} = 1;  # Suppress output during tests
}

{
    my ($stdout, $stderr, $exit) = capture {
        system($^X, "$RealBin/../bin/json_generator.pl", "-e");
    };
    isnt($exit, 0, 'Script fails when -e used without -i');
    like($stderr, qr/requires.*-i/, 'Error message mentions -i requirement');
}

use KarabinerGenerator::KarabinerJsonFile qw(
    read_karabiner_json 
    write_karabiner_json 
    get_current_profile_rules
    update_generated_rules
);

# Get paths from Config.pm
my $complex_mods_dir = get_path('complex_mods_dir');
my $karabiner_fixture = get_path('karabiner_json');
my $test_karabiner = $karabiner_fixture;

# Create complex modifications directory if it doesn't exist
make_path($complex_mods_dir) unless -d $complex_mods_dir;

# Read and write karabiner fixture to test location
my $config = read_karabiner_json($karabiner_fixture);
ok(write_karabiner_json($config, $test_karabiner), 'Setup test karabiner.json');

# Create a mock config.yaml for testing
my $config_yaml = get_path('config_yaml');
open my $fh, '>', $config_yaml or die "Cannot create config.yaml: $!";
print $fh "---\napp_activators:\n  modifiers:\n    double_tap_rshift:\n      apps:\n        - Safari\n";
close $fh;

# Test -e with -i
{
    local $ENV{KARABINER_JSON} = $test_karabiner; 
    local $ENV{COMPLEX_MODS_DIR} = $complex_mods_dir;
    local $ENV{CONFIG_FILE} = $config_yaml;

    my ($stdout, $stderr, $exit) = capture {
        system($^X, "$RealBin/../bin/json_generator.pl", "-i", "-e");
    };
    
    is($exit, 0, 'Script succeeds with both -i and -e')
        or diag("stdout: $stdout\nstderr: $stderr");
    
    # Verify rules were added
    my $updated_config = read_karabiner_json($test_karabiner);
    my $rules = get_current_profile_rules($updated_config, 'Generated Json');
    ok(@$rules, 'Rules were added to Generated Json profile');
}

# Test command line integration
subtest 'Command line integration' => sub {
    plan tests => 4;
    
    # Test -e without -i
    {
        my ($stdout, $stderr, $exit) = capture {
            system($^X, "$RealBin/../bin/json_generator.pl", "-e");
        };
        isnt($exit, 0, 'Script fails when -e used without -i');
        like($stderr, qr/requires.*-i/, 'Error message mentions -i requirement');
    }
    
    # Test -e with -i
    {
        local $ENV{KARABINER_JSON} = $test_karabiner;
        local $ENV{COMPLEX_MODS_DIR} = $complex_mods_dir;
        local $ENV{CONFIG_FILE} = $config_yaml;

        my ($stdout, $stderr, $exit) = capture {
            system($^X, "$RealBin/../bin/json_generator.pl", "-i", "-e");
        };
        is($exit, 0, 'Script succeeds with both -i and -e');
        
        # Verify rules were added
        my $updated_config = read_karabiner_json($test_karabiner);
        my $rules = get_current_profile_rules($updated_config, 'Generated Json');
        ok(@$rules, 'Rules were added to Generated Json profile');
    }
};


done_testing();