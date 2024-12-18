# t/profiles/author/01_inspect_test.t - Save test environment state for inspection

use strict;
use warnings;
use Test::Most 'die';
use FindBin qw($RealBin);
use lib "$RealBin/../../../lib";
use File::Copy::Recursive qw(dircopy); 
use File::Copy qw(copy);
use KarabinerGenerator::Config qw(get_path mode reset_test_environment);
use KarabinerGenerator::Profiles qw(ensure_profile_environment);

BEGIN {
   unless ($ENV{AUTHOR_TESTING}) {
       plan(skip_all => 'Author testing. Set $ENV{AUTHOR_TESTING} to run');
   }
}

# Force test mode and clean environment
reset_test_environment();

# Get test environment directory to pass to script
my $test_dir = File::Basename::dirname(get_path('config_yaml'));

# Add debug output
diag("Test setup paths:");
diag("config_yaml: " . get_path('config_yaml'));
diag("templates_dir: " . get_path('templates_dir'));
diag("generated_json_dir: " . get_path('generated_json_dir'));
diag("complex_mods_dir: " . get_path('complex_mods_dir'));

# Ensure proper profile environment setup
ok(ensure_profile_environment(), "Profile environment setup successful") 
   or diag("Failed to set up profile environment");

# Copy ctrl-esc.json.tpl from fixtures
my $template_src = get_path('ctrl_esc_template');
my $template_dest = get_path('templates_dir') . '/ctrl-esc.json.tpl';

ok(copy($template_src, $template_dest), "Copied ctrl-esc template")
   or diag("Failed to copy template: $!");

# Run generator with profiles enabled and TEST_MODE set
local $ENV{TEST_MODE} = 1;
local $ENV{TEST_DIR} = $test_dir;
my $cmd = get_path('json_generator');
diag("\nRunning command: $cmd -i -p");
my $output = `$cmd -i -p`;
diag($output);

# Verify the test directory still exists and has our files
ok(-d $test_dir, "Test directory exists at: $test_dir");

done_testing;