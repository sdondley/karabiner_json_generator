# 06_profiles.t - Test profile generation and installation
use strict;
use warnings;
use Test::Most 'die';
use File::Spec;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
require "$RealBin/../../bin/json_generator.pl";
use KarabinerGenerator::Config qw(get_path load_config);
use KarabinerGenerator::Init qw(init db dbd);
use KarabinerGenerator::JSONHandler qw(read_json_file);
use KarabinerGenerator::TestEnvironment::Loader qw(
    load_project_defaults 
    load_karabiner_defaults
    load_test_fixtures
);
use KarabinerGenerator::Profiles qw(PROFILE_PREFIX);

# Initialize test environment
init();
load_project_defaults();
load_karabiner_defaults();
load_test_fixtures();

# Load and verify profile configuration
my $config = load_config();
ok($config->{profiles}, "Profile configuration loaded");
ok($config->{profiles}{profiles}, "Profiles section exists in configuration");
ok($config->{profiles}{profiles}{Default}, "Default profile exists in configuration");
ok($config->{profiles}{common}{rules}, "Common rules exist in configuration");
ok(grep { $_ eq 'ctrl-esc' } @{$config->{profiles}{common}{rules}}, "ctrl-esc exists in common rules");

# Run generator with --install --profiles flags
my $generated_files = KarabinerGenerator::Generator->run(
    install => 1,
    profiles => 1
);

# First verify that triggers and complex_mods were installed correctly
my $complex_mods_dir = get_path('karabiner_complex_mods_dir');

# Check trigger files were copied
my $triggers_dir = get_path('generated_triggers_dir');
for my $file (@$generated_files) {
    my $basename = (File::Spec->splitpath($file))[2];
    my $installed_file = File::Spec->catfile($complex_mods_dir, $basename);
    ok(-f $installed_file, "Trigger file $basename was copied to complex_modifications");
}

# Verify bundled profile was NOT copied
my $profile_file = File::Spec->catfile($complex_mods_dir, PROFILE_PREFIX . "-Default.json");
ok(!-f $profile_file, "Profile bundle was not copied to complex_modifications directory");

# Read karabiner.json and verify profile creation
my $karabiner_json = get_path('karabiner_json');
my $kb_config = read_json_file($karabiner_json);
db("\nDebug karabiner.json content:");
dbd("Karabiner config", $kb_config);

# Verify GJ-Default profile exists and has correct structure
my ($gj_profile) = grep { $_->{name} eq PROFILE_PREFIX . '-Default' } @{$kb_config->{profiles}};
ok($gj_profile, "GJ-Default profile was added to karabiner.json");

# Verify profile has correct basic structure
ok($gj_profile->{complex_modifications}, "Profile has complex_modifications section");
ok($gj_profile->{complex_modifications}{rules}, "Profile has rules array");
ok(ref($gj_profile->{complex_modifications}{rules}) eq 'ARRAY', "Rules is an array");

# Verify ctrl-esc rule was added correctly
my $found_ctrl_esc = 0;
for my $rule (@{$gj_profile->{complex_modifications}{rules}}) {
    if ($rule->{description} =~ /Change.*control.*esc/i) {
        $found_ctrl_esc = 1;
        ok(ref($rule->{manipulators}) eq 'ARRAY', "Rule has manipulators array");
        my $manipulator = $rule->{manipulators}[0];
        is($manipulator->{type}, 'basic', "Manipulator has correct type");
        is($manipulator->{from}{key_code}, 'caps_lock', "From key is caps_lock");
        ok($manipulator->{to}, "Has 'to' configuration");
        ok($manipulator->{to_if_alone}, "Has 'to_if_alone' configuration");
        last;
    }
}
ok($found_ctrl_esc, "ctrl-esc rule exists in profile");

done_testing();