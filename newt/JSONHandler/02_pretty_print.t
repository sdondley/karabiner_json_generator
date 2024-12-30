# newt/JSONHandler/02_pretty_print.t

use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use File::Spec;

use KarabinerGenerator::Init qw(init db dbd);
use KarabinerGenerator::Config qw(get_path);
use KarabinerGenerator::TestEnvironment::Loader qw(load_test_fixtures);
use KarabinerGenerator::JSONHandler qw(write_json_file read_json_file);

init();
load_test_fixtures();

# First read the fixture 
my $test_file = File::Spec->catfile(get_path('generated_json_dir'), 'test.json');
my $json = read_json_file($test_file);

# Write it back out to a new file
my $output_file = File::Spec->catfile(get_path('generated_json_dir'), 'output.json');
write_json_file($output_file, $json);

# Check the output file formatting
open my $fh, '<', $output_file or die "Cannot open $output_file: $!";
my $content = do { local $/; <$fh> };
close $fh;

# Check proper indentation 
like($content, qr/^\{$/m, "Opening brace on own line");
like($content, qr/^  "title":/m, "Title indented 2 spaces");
like($content, qr/^  "rules": \[$/m, "Rules array starts properly");
like($content, qr/^    \{$/m, "Rule object indented 4 spaces");
like($content, qr/^      "description":/m, "Description indented 6 spaces");

# Check closing format
like($content, qr/^    \}$/m, "Rule closing brace properly indented");
like($content, qr/^  \]$/m, "Rules array closing bracket properly indented");
like($content, qr/^\}$/m, "Final closing brace on own line");

done_testing();