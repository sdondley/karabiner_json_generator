# t/profiles/05_installation.t - Test profile installation functionality

use strict;
use warnings;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use File::Spec;
use File::Path qw(make_path remove_tree);
use YAML::XS qw(DumpFile);

use KarabinerGenerator::Config qw(get_path reset_test_environment);
use KarabinerGenerator::Profiles qw(
    PROFILE_PREFIX 
    get_profile_names 
    generate_config 
    bundle_profile 
    install_bundled_profile
);

# Reset test environment
reset_test_environment();

# Get necessary paths
my $json_dir = get_path('generated_json_dir');
my $profiles_dir = get_path('generated_profiles_dir');
my $complex_mods_dir = get_path('complex_mods_dir');
my $profile_config = get_path('profile_config_yaml');

# Clean start
for my $dir ($json_dir, $profiles_dir, $complex_mods_dir) {
    remove_tree($dir) if -d $dir;
    make_path($dir);
}
unlink $profile_config if -f $profile_config;

# Create test JSON files
for my $file (qw(test1.json test2.json common.json)) {
    open my $fh, '>', File::Spec->catfile($json_dir, $file) or die "Cannot create $file: $!";
    print $fh '{"rules":[{"description":"Test rule"}]}';
    close $fh;
}

# Test get_profile_names with no config
{
    my @names = get_profile_names();
    is_deeply(\@names, [], 'No profiles returned when config missing');
}

# Generate default config and test get_profile_names
{
    ok(generate_config(), 'Config generation successful');
    my @names = get_profile_names();
    is_deeply(\@names, ['Default'], 'Default profile found in generated config');
}

# Test profile bundling and installation
{
    my $profile_name = 'Default';
    
    # Bundle the profile
    ok(bundle_profile($profile_name), 'Profile bundling successful');
    my $bundle_file = File::Spec->catfile($profiles_dir, PROFILE_PREFIX . "-$profile_name.json");
    ok(-f $bundle_file, 'Bundle file was created');
    
    # Install the bundle
    ok(install_bundled_profile($profile_name), 'Profile installation successful');
    my $installed_file = File::Spec->catfile($complex_mods_dir, PROFILE_PREFIX . "-$profile_name.json");
    ok(-f $installed_file, 'Profile was installed to complex modifications directory');
    
    # Test installation with missing bundle
    unlink $bundle_file;
    ok(!install_bundled_profile($profile_name), 'Installation fails when bundle missing');
}

# Test with multiple profiles
{
    # Create config with multiple profiles
    my $config = {
        common => {
            rules => ['common']
        },
        profiles => {
            Default => {
                title => 'Default Profile',
                common => \1,
                rules => ['test1']
            },
            Gaming => {
                title => 'Gaming Profile',
                common => \0,
                rules => ['test2']
            }
        }
    };
    DumpFile($profile_config, $config);
    
    # Test profile enumeration
    my @names = sort(get_profile_names());
    is_deeply(\@names, ['Default', 'Gaming'], 'All profiles found in config');
    
    # Test bundling and installation of all profiles
    for my $profile_name (@names) {
        ok(bundle_profile($profile_name), "Bundling successful for $profile_name");
        ok(install_bundled_profile($profile_name), "Installation successful for $profile_name");
        
        my $installed_file = File::Spec->catfile(
            $complex_mods_dir, 
            PROFILE_PREFIX . "-$profile_name.json"
        );
        ok(-f $installed_file, "Installed file exists for $profile_name");
    }
}

# Clean up
remove_tree($json_dir, $profiles_dir, $complex_mods_dir);
unlink $profile_config;

done_testing();