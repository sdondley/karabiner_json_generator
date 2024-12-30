# newt/Template/02_dtrs.t
use strict;
use warnings;
use Test::More;
use Test::Exception;
use JSON qw(decode_json);
use FindBin;
use File::Spec;
use lib "$FindBin::Bin/../../lib";

use KarabinerGenerator::Init qw(init is_test_mode db dbd);
use KarabinerGenerator::Config qw(get_path load_config);
use KarabinerGenerator::Template qw(process_templates);
use KarabinerGenerator::TestEnvironment::Loader qw(
    load_project_defaults
    load_karabiner_defaults
    load_test_fixtures
);

# Initialize test environment
db("\n### Starting Template DTRS Test ###");
db("Initializing environment");
init();

# Load defaults first, then test-specific fixtures
load_project_defaults();
load_karabiner_defaults();
load_test_fixtures();

# Load config and process templates
my $config = load_config();
my @generated_files = process_templates($config);

# Verify both DTLS and DTRS files were generated
my $trigger_dir = File::Spec->catdir(get_path('generated_json_dir'), 'triggers');
my $dtls_file = File::Spec->catfile($trigger_dir, 'app_activators_dtls.json');
my $dtrs_file = File::Spec->catfile($trigger_dir, 'app_activators_dtrs.json');

ok(-f $dtls_file, "DTLS file exists");
ok(-f $dtrs_file, "DTRS file exists");

# Read and parse DTRS JSON
my $dtrs_json = do {
    open(my $fh, '<', $dtrs_file) or die "Can't open $dtrs_file: $!";
    local $/;
    <$fh>;
};

my $dtrs_data = decode_json($dtrs_json);

# Basic structure tests
ok(exists $dtrs_data->{title}, "JSON has title field");
ok(exists $dtrs_data->{rules}, "JSON has rules field");
is(ref $dtrs_data->{rules}, 'ARRAY', "rules is an array");

# Test Chrome rule content in DTRS
my ($chrome_rule) = grep { $_->{description} =~ /Chrome/ } @{$dtrs_data->{rules}};
ok(defined $chrome_rule, "Found Chrome rule");
is($chrome_rule->{manipulators}->[0]->{from}->{key_code}, "c", 
   "Chrome rule uses 'c' key");
is($chrome_rule->{manipulators}->[0]->{conditions}->[0]->{name}, 
   "double_tap_rshift", "Chrome rule uses double_tap_rshift condition");
like($chrome_rule->{manipulators}->[0]->{to}->[0]->{shell_command}, 
     qr/Chrome'$/, "Shell command ends with Chrome");

# Test Firefox rule content in DTRS
my ($firefox_rule) = grep { $_->{description} =~ /Firefox/ } @{$dtrs_data->{rules}};
ok(defined $firefox_rule, "Found Firefox rule");
is($firefox_rule->{manipulators}->[0]->{from}->{key_code}, "f", 
   "Firefox rule uses 'f' key");

# Verify DTLS still works (regression test)
my $dtls_json = do {
    open(my $fh, '<', $dtls_file) or die "Can't open $dtls_file: $!";
    local $/;
    <$fh>;
};

my $dtls_data = decode_json($dtls_json);
my ($iterm_rule) = grep { $_->{description} =~ /iTerm/ } @{$dtls_data->{rules}};
ok(defined $iterm_rule, "DTLS iTerm rule still exists");
is($iterm_rule->{manipulators}->[0]->{from}->{key_code}, "i", 
   "DTLS iTerm rule still uses 'i' key");

done_testing();