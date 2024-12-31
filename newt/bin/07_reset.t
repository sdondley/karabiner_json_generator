# 07_reset.t - Test reset feature of json_generator.pl
use strict;
use warnings;
use Test::Most 'die';
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
require "$RealBin/../../bin/json_generator.pl";
use KarabinerGenerator::Config qw(get_path load_config);  # Added load_config
use KarabinerGenerator::Init qw(init db);
use KarabinerGenerator::TestEnvironment::Loader qw(load_project_defaults load_karabiner_defaults);
use KarabinerGenerator::JSONHandler qw(read_json_file);
use KarabinerGenerator::Template qw(process_templates);

init();
load_project_defaults();
load_karabiner_defaults();

# First generate some files that should be cleaned up
my $initial_config = load_config();  # Renamed to avoid duplicate declaration
my @generated_files = process_templates($initial_config);
ok(@generated_files > 0, 'Generated some files for testing cleanup');

# Run the script with reset option
lives_ok(
    sub { KarabinerGenerator::Generator->run(reset => 1, quiet => 1) },
    'Reset command executes without errors'
);

# Check that generated files were cleaned up
for my $file (@generated_files) {
    ok(!-f $file, "Generated file was cleaned up: $file");
}

# Check the resulting karabiner.json file
my $karabiner_json = get_path('karabiner_json');
ok(-f $karabiner_json, 'karabiner.json exists');

my $config = read_json_file($karabiner_json);  # This declaration is now unique

# Test the basic structure
ok($config->{global}, 'Global settings exist');
ok($config->{profiles}, 'Profiles array exists');
is(@{$config->{profiles}}, 1, 'Single profile exists');

# Test the default profile
my $default_profile = $config->{profiles}[0];
is($default_profile->{name}, 'Default', 'Default profile has correct name');
ok($default_profile->{selected}, 'Default profile is selected');
ok($default_profile->{complex_modifications}, 'Complex modifications exist');
is_deeply(
    $default_profile->{complex_modifications}{rules},
    [],
    'Rules array is empty'
);

# Test that reset can't be used with other options
throws_ok(
    sub { KarabinerGenerator::Generator->run(reset => 1, install => 1) },
    qr/--reset cannot be used with other options/,
    'Reset cannot be used with other options'
);

done_testing();