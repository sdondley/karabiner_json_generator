# File: t/04_validator.t
use strict;
use warnings;
use Test::More tests => 1;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";

use KarabinerGenerator::Validator qw(validate_files);

my $KARABINER_CLI = '/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli';

subtest 'File Validation' => sub {
    plan tests => 4;

    my $fixtures_dir = "$RealBin/fixtures";

    my $valid_file = "$fixtures_dir/valid_complex_mod.json";
    my $invalid_file = "$fixtures_dir/invalid_complex_mod.json";
    my $malformed_file = "$fixtures_dir/malformed_complex_mod.json";

    # Run validations with actual karabiner_cli
    my $result_valid = validate_files($KARABINER_CLI, $valid_file);
    ok($result_valid, 'Valid JSON passes validation');

    my $result_invalid = validate_files($KARABINER_CLI, $invalid_file);
    ok(!$result_invalid, 'Invalid JSON fails validation');

    my $result_malformed = validate_files($KARABINER_CLI, $malformed_file);
    ok(!$result_malformed, 'Malformed JSON fails validation');

    my $result_multiple = validate_files($KARABINER_CLI, $valid_file, $invalid_file);
    ok(!$result_multiple, 'Multiple files with one invalid file fails validation');
};