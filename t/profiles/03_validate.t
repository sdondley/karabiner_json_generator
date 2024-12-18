# t/profiles/03_validate.t - Profile configuration validation tests

use strict;
use warnings;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use File::Path qw(make_path remove_tree);
use File::Spec;
use YAML::XS qw(DumpFile);

use KarabinerGenerator::Config qw(get_path reset_test_environment);
use KarabinerGenerator::Profiles qw(validate_profile_config);

# Reset test environment
reset_test_environment();

# Set up test directories and files
my $generated_json_dir = get_path('generated_json_dir');
my $profile_config = get_path('profile_config_yaml');

# Clean start
remove_tree($generated_json_dir) if -d $generated_json_dir;
unlink $profile_config if -f $profile_config;
make_path($generated_json_dir);

# Create some test JSON files
my @test_files = ('ctrl-esc.json', 'test1.json', 'test2.json');
for my $file (@test_files) {
    my $path = File::Spec->catfile($generated_json_dir, $file);
    open(my $fh, '>', $path) or die "Cannot create $path: $!";
    print $fh "{}";  # Empty valid JSON
    close($fh);
}

# Test 1: Valid configuration
{
    my $config = {
        common => {
            rules => ['ctrl-esc']
        },
        profiles => {
            Default => {
                title => 'Default',
                common => \1,
                rules => ['test1']
            }
        }
    };
    
    DumpFile($profile_config, $config);
    
    my $result = validate_profile_config();
    ok($result->{valid}, 'Valid configuration passes validation');
    is_deeply($result->{missing_files}, [], 'No missing files reported');
}

# Test 2: Missing files
{
    my $config = {
        common => {
            rules => ['missing-file']
        },
        profiles => {
            Default => {
                title => 'Default',
                common => \1,
                rules => ['another-missing-file']
            }
        }
    };
    
    DumpFile($profile_config, $config);
    
    my $result = validate_profile_config();
    ok(!$result->{valid}, 'Invalid configuration fails validation');
    is_deeply(
        [sort @{$result->{missing_files}}],
        ['another-missing-file.json', 'missing-file.json'],
        'Correct missing files reported'
    );
}

# Test 3: Mixed valid and invalid files
{
    my $config = {
        common => {
            rules => ['ctrl-esc', 'missing-common']
        },
        profiles => {
            Default => {
                title => 'Default',
                common => \1,
                rules => ['test1', 'missing-profile']
            }
        }
    };
    
    DumpFile($profile_config, $config);
    
    my $result = validate_profile_config();
    ok(!$result->{valid}, 'Configuration with some missing files fails validation');
    is_deeply(
        [sort @{$result->{missing_files}}],
        ['missing-common.json', 'missing-profile.json'],
        'Only actually missing files are reported'
    );
}

# Test 4: Empty rules arrays
{
    my $config = {
        common => {
            rules => []
        },
        profiles => {
            Default => {
                title => 'Default',
                common => \1,
                rules => []
            }
        }
    };
    
    DumpFile($profile_config, $config);
    
    my $result = validate_profile_config();
    ok($result->{valid}, 'Configuration with empty rules arrays is valid');
    is_deeply($result->{missing_files}, [], 'No missing files reported for empty rules');
}

# Test 5: Missing config file
{
    unlink $profile_config if -f $profile_config;
    
    my $result = validate_profile_config();
    ok(!$result->{valid}, 'Missing config file fails validation');
    ok(exists $result->{error}, 'Error message exists for missing config');
    like($result->{error}, qr/config file/i, 'Error message mentions config file');
}

# Clean up
remove_tree($generated_json_dir);
unlink $profile_config if -f $profile_config;

done_testing();