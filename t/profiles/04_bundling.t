# t/profiles/04_bundling.t - Test profile bundling functionality

use strict;
use warnings;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use File::Spec;
use File::Path qw(make_path remove_tree);
use YAML::XS qw(DumpFile);

use KarabinerGenerator::Config qw(get_path reset_test_environment);
use KarabinerGenerator::Profiles qw(PROFILE_PREFIX bundle_profile);

# Reset test environment
reset_test_environment();

# Get necessary paths
my $json_dir = get_path('generated_json_dir');
my $profiles_dir = get_path('generated_profiles_dir');
my $profile_config = get_path('profile_config_yaml');

# Clean start
remove_tree($json_dir) if -d $json_dir;
remove_tree($profiles_dir) if -d $profiles_dir;
unlink $profile_config if -f $profile_config;

# Create test JSON files
make_path($json_dir);
for my $file (qw(test1.json test2.json common.json)) {
    open my $fh, '>', File::Spec->catfile($json_dir, $file) or die "Cannot create $file: $!";
    print $fh "{}";  # Empty valid JSON
    close $fh;
}

# Create test profile config
my $config = {
    common => {
        rules => ['common']
    },
    profiles => {
        Default => {
            title => 'Default Profile',
            common => \1,
            rules => ['test1', 'test2']
        }
    }
};
DumpFile($profile_config, $config);

# Test bundling
{
    my $result = bundle_profile('Default');
    ok($result, 'Profile bundling successful');
    
    # Check directory creation
    ok(-d $profiles_dir, 'Generated profiles directory was created');
    
    # Check bundled file
    my $profile_file = File::Spec->catfile($profiles_dir, 'GJ-Default.json');
    ok(-f $profile_file, 'Bundled profile file was created');
}

# Clean up
remove_tree($json_dir);
remove_tree($profiles_dir);
unlink $profile_config;

done_testing();