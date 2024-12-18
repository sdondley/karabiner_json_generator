# t/profiles/02_config_file.t - Profile configuration file tests

use strict;
use warnings;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use YAML::XS qw(LoadFile);

use KarabinerGenerator::Config qw(get_path);
use KarabinerGenerator::Profiles qw(has_profile_config generate_config);

# Clean environment
my $profile_config = get_path('profile_config_yaml');
unlink $profile_config if -f $profile_config;

# Test initial state
ok(!has_profile_config(), 'Config file does not exist initially');

# Test explicit generation
ok(generate_config(), 'generate_config() returns true on success');
ok(has_profile_config(), 'Config file exists after generation');
ok(-f $profile_config, 'Config file physically exists');

# Test content of generated file
my $config = LoadFile($profile_config);

# Test common section
ok(exists $config->{common}, 'Common section exists');
ok(exists $config->{common}{rules}, 'Common rules section exists');
is_deeply($config->{common}{rules}, ['ctrl-esc'], 'Common rules contains expected entry');

# Test profiles section
ok(exists $config->{profiles}, 'Profiles section exists');
ok(exists $config->{profiles}{Default}, 'Default profile exists');
is($config->{profiles}{Default}{title}, 'Default', 'Default profile has correct title');
ok($config->{profiles}{Default}{common}, 'Default profile has common set to true');

# Test regeneration
unlink $profile_config;
ok(!-f $profile_config, 'Config file successfully deleted');
ok(generate_config(), 'Can regenerate config file');
ok(-f $profile_config, 'Config file exists after regeneration');

# Clean up
unlink $profile_config;

done_testing;