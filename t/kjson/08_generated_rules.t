use strict;
use warnings;
use Test::Most tests => 4, 'die';
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use JSON;
use File::Path qw(make_path remove_tree);
use File::Spec;

# Import the config module with required functions
use KarabinerGenerator::Config qw(mode get_path);

# Setup test environment
BEGIN {
    mode('test');  # Ensure we're in test mode
}

# Test module loading
use_ok('KarabinerGenerator::KarabinerJsonFile', qw(
    read_karabiner_json
    write_karabiner_json
    get_profile_names
    get_current_profile_rules
    update_generated_rules
));

# Get paths from Config.pm
my $karabiner_json = get_path('karabiner_json');
my $complex_mods_dir = get_path('complex_mods_dir');
my $generated_json_dir = get_path('generated_json_dir');

# Clean and setup test files
sub setup_test_files {
    # Clean up existing files
    if (-d $complex_mods_dir) {
        remove_tree($complex_mods_dir);
    }
    make_path($complex_mods_dir);
    
    # Create valid test JSON files
    my @test_files = (
        {
            name => 'test_1.json',
            content => {
                title => "Test Rule 1",
                rules => [{ description => "Rule 1" }]
            }
        },
        {
            name => 'test_2.json',
            content => {
                title => "Test Rule 2",
                rules => [{ description => "Rule 2" }]
            }
        }
    );
    
    for my $file (@test_files) {
        my $filepath = File::Spec->catfile($complex_mods_dir, $file->{name});
        open my $fh, '>', $filepath 
            or die "Cannot create $filepath: $!";
        print $fh encode_json($file->{content});
        close $fh;
    }
}

# Test update_generated_rules function
subtest 'Update generated rules' => sub {
    plan tests => 6;
    
    # Set up test files
    setup_test_files();
    
    my $test_output = File::Spec->catfile($generated_json_dir, 'test_generated.json');
    my $config = read_karabiner_json($karabiner_json);
    
    ok(update_generated_rules($config, $complex_mods_dir), 'Updated generated rules');
    ok(write_karabiner_json($config, $test_output), 'Wrote updated config');
    
    # Verify results
    my $updated_config = read_karabiner_json($test_output);
    my $profiles = get_profile_names($updated_config);
    ok(grep(/^Generated Json$/, @$profiles), 'Generated Json profile exists');
    
    my $rules = get_current_profile_rules($updated_config, 'Generated Json');
    ok($rules, 'Got rules from Generated Json profile');
    is(ref($rules), 'ARRAY', 'Rules is an array');
    
    # We expect exactly 2 rules from our test files
    is(scalar(@$rules), 2, 'All rules were imported');
};

# Test with empty rules directory
subtest 'Empty rules directory' => sub {
    plan tests => 3;
    
    my $empty_dir = File::Spec->catdir($generated_json_dir, 'empty');
    if (-d $empty_dir) {
        remove_tree($empty_dir);
    }
    make_path($empty_dir);
    
    my $test_output = File::Spec->catfile($generated_json_dir, 'test_empty.json');
    my $config = read_karabiner_json($karabiner_json);
    
    ok(update_generated_rules($config, $empty_dir), 'Updated with empty directory');
    ok(write_karabiner_json($config, $test_output), 'Wrote config');
    
    my $updated_config = read_karabiner_json($test_output);
    my $rules = get_current_profile_rules($updated_config, 'Generated Json');
    is(scalar(@$rules), 0, 'No rules in profile with empty directory');
};

# Test error conditions
subtest 'Error conditions' => sub {
    plan tests => 2;
    
    my $config = read_karabiner_json($karabiner_json);
    
    # Test with non-existent directory
    ok(!update_generated_rules($config, '/nonexistent/dir'), 
       'Handles non-existent directory');
    
    # Test with invalid config
    ok(!update_generated_rules({}, $complex_mods_dir),
       'Handles invalid config');
};