# newt/JSONHandler/01_basic.t

use strict;
use warnings;
use Test::More;
use File::Spec;

use KarabinerGenerator::Init qw(init db dbd);
use KarabinerGenerator::Config qw(get_path);
use KarabinerGenerator::TestEnvironment::Loader qw(load_test_fixtures);
use KarabinerGenerator::JSONHandler qw(
    read_json_file
    write_json_file
    validate_json
);

# Initialize test environment and load fixtures from correct location
db("\n### Starting JSON Handler tests ###");
init();
load_test_fixtures();

db("Getting test file path");
my $test_file = File::Spec->catfile(get_path('generated_json_dir'), 'test.json');
db("Test file path: $test_file");

db("Testing read_json_file()");
my $data = read_json_file($test_file);

db("Validating read data structure");
dbd($data);

ok($data->{title} eq 'Test Profile', 'JSON data read correctly');
ok(ref $data->{rules} eq 'ARRAY', 'Rules is an array');
is(scalar @{$data->{rules}}, 1, 'Has one rule');

db("Testing write_json_file()");
my $output_file = File::Spec->catfile(get_path('generated_json_dir'), 'output.json');
db("Output file path: $output_file");

ok(write_json_file($output_file, $data), 'Write JSON file');
ok(-f $output_file, 'Output file was created');
db("Output file exists: " . (-f $output_file ? "YES" : "NO"));

db("Testing JSON validation");
ok(validate_json($data), 'Valid JSON structure passes validation');

db("Testing invalid JSON validation");
my $invalid_data = { rules => "not an array" };
ok(!validate_json($invalid_data), 'Invalid JSON structure fails validation');

db("Testing error handling for nonexistent file");
eval { read_json_file('nonexistent.json') };
like($@, qr/File does not exist/, 'Proper error for nonexistent file');
db("Error message: $@");

done_testing();