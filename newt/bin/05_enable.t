use strict;
use warnings;
use Test::Most 'die';
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
require "$RealBin/../../bin/json_generator.pl";
use KarabinerGenerator::Config qw(get_path);
use KarabinerGenerator::Init qw(init db dbd);
use KarabinerGenerator::JSONHandler qw(read_json_file);
use KarabinerGenerator::TestEnvironment::Loader qw(
    load_project_defaults
    load_karabiner_defaults
);

init();
load_project_defaults();
load_karabiner_defaults();

# Run with --install --enable
my $generated_files = KarabinerGenerator::Generator->run(
    install => 1,
    enable => 1
);

# Check karabiner.json was updated correctly
my $karabiner_json = get_path('karabiner_json');
my $config = read_json_file($karabiner_json);

ok($config->{profiles}, "Config has profiles");
my ($profile) = grep { $_->{name} eq 'Generated JSON' } @{$config->{profiles}};
ok($profile, "Generated JSON profile exists");
ok($profile->{complex_modifications}{rules}, "Profile has rules array");
ok(scalar(@{$profile->{complex_modifications}{rules}}), "Rules were added to profile");

done_testing();