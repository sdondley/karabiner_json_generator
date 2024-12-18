# t/profiles/07_generation_output.t

use strict;
use warnings;
use Test::Most 'die';
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use Capture::Tiny qw(capture);
use File::Copy qw(copy);
use File::Spec;
use Cwd qw(getcwd);
use File::Basename qw(dirname);

use KarabinerGenerator::Config qw(get_path mode reset_test_environment);

# Set up test mode
BEGIN {
    $ENV{TEST_MODE} = 1;
    $ENV{QUIET} = 1;  # Changed from 0 to 1 to suppress messages
}

mode('test');
reset_test_environment();

# Get paths from Config.pm
my $json_dir = get_path('generated_json_dir');
my $templates_dir = get_path('templates_dir');
my $complex_mods_dir = get_path('complex_mods_dir');

# Save current directory and change to project root
my $orig_dir = getcwd();
my $project_root = dirname(dirname($RealBin));
chdir $project_root or die "Cannot chdir to project root: $!";

# Copy ctrl-esc.json.tpl from fixtures to test templates dir
my $fixture_file = File::Spec->catfile($RealBin, '..', 'fixtures', 'ctrl-esc.json.tpl');
copy($fixture_file, File::Spec->catfile($templates_dir, 'ctrl-esc.json.tpl')) 
    or die "Failed to copy ctrl-esc.json.tpl: $!";

# Run the generator with needed flags
my ($stdout, $stderr, $exit) = capture {
    local $ENV{PERL5LIB} = join(':', @INC);
    local $ENV{TEST_MODE} = 1;
    system("$^X bin/json_generator.pl -i -d");
};

# Change back to original directory
chdir $orig_dir or die "Cannot chdir back to original dir: $!";

# Basic execution test
is($exit >> 8, 0, "Generator executed successfully");

# Only check directories we expect to exist when not in profile mode
for my $dir ($json_dir, $complex_mods_dir) {
    ok(-d $dir, "Directory exists: $dir");
}

my @output_jsons = glob("$json_dir/*.json");
ok(@output_jsons > 0, "JSON files were generated");

done_testing();