# newt/Template/01_basic.t
use strict;
use warnings;
use Test::Most 'die';
use Test::Exception;
use JSON qw(decode_json);
use FindBin;
use File::Spec;
use lib "$FindBin::Bin/../../lib";

use KarabinerGenerator::Init qw(init is_test_mode db);
use KarabinerGenerator::Config qw(get_path load_config);
use KarabinerGenerator::Template qw(process_templates);
use KarabinerGenerator::TestEnvironment::Loader qw(
    load_project_defaults
    load_karabiner_defaults
);

# Initialize the test environment
db("\n### Starting Template Basic Test ###");
db("Checking test mode and initializing environment");
init();
load_project_defaults();
load_karabiner_defaults();

# Load config and process templates
db("Loading config");
my $config = load_config();
db("Config loaded: " . ($config ? "yes" : "no"));

db("Processing templates");
my @generated_files = process_templates($config);
db("Number of files generated: " . scalar @generated_files);

# Test directory structure
db("\nVerifying directory structure");
my %dir_counts;
for my $file (@generated_files) {
    db("Checking file: $file");
    my $dir = File::Spec->catpath((File::Spec->splitpath($file))[0,1]);
    $dir_counts{$dir}++;
    db("Added to directory count: $dir");
}

# Get paths from Config
my $output_dir = get_path('generated_json_dir');
my $trigger_dir = File::Spec->catdir($output_dir, 'triggers');
my $complex_dir = File::Spec->catdir($output_dir, 'complex_modifiers');

db("\nChecking output directories");
db("trigger_dir: $trigger_dir");
db("complex_dir: $complex_dir");

# Print counts for debugging
db("\nFiles per directory:");
for my $dir (sort keys %dir_counts) {
    db("  $dir: $dir_counts{$dir} files");
}

# Verify app_activators_dtls.json content
my $app_activators_file = File::Spec->catfile($trigger_dir, 'app_activators_dtls.json');
ok(-f $app_activators_file, "app_activators_dtls.json exists");

my $json_text = do {
    open(my $fh, '<', $app_activators_file) or die "Can't open $app_activators_file: $!";
    local $/;
    <$fh>;
};

my $json_data = decode_json($json_text);

# Basic structure tests
ok(exists $json_data->{title}, "JSON has title field");
ok(exists $json_data->{rules}, "JSON has rules field");
is(ref $json_data->{rules}, 'ARRAY', "rules is an array");

# Test iTerm rule content
my ($iterm_rule) = grep { $_->{description} =~ /iTerm/ } @{$json_data->{rules}};
ok(defined $iterm_rule, "Found iTerm rule");
is($iterm_rule->{manipulators}->[0]->{from}->{key_code}, "i", "iTerm rule uses 'i' key");
is($iterm_rule->{manipulators}->[0]->{conditions}->[0]->{name}, "double_tap_lshift", 
   "iTerm rule uses double_tap_lshift condition");
like($iterm_rule->{manipulators}->[0]->{to}->[0]->{shell_command}, 
     qr/iTerm'$/, "Shell command ends with iTerm");

db("\n### Template Basic Test Complete ###");
done_testing();