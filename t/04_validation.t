use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";

# Load modules
use_ok('KarabinerGenerator::Validator', 'validate_files') 
    or BAIL_OUT("Couldn't load KarabinerGenerator::Validator");

use KarabinerGenerator::Config qw(get_path mode);

# Ensure we're in test mode
BEGIN {
    $ENV{QUIET} = 1;
}

# Verify we're in test mode
is(mode(), 'test', 'Running in test mode');

subtest 'Path Verification' => sub {
    # Verify that the test files exist
    ok(-f get_path('valid_complex_mod'), 'Valid complex mod fixture exists');
    ok(-f get_path('invalid_complex_mod'), 'Invalid complex mod fixture exists');
    ok(-f get_path('malformed_complex_mod'), 'Malformed complex mod fixture exists');
};

subtest 'File Validation' => sub {
    # Test valid JSON passes
    ok(validate_files(get_path('valid_complex_mod')), 'Valid JSON passes validation')
        or diag("Valid JSON validation failed");

    # Test invalid JSON fails
    ok(!validate_files(get_path('invalid_complex_mod')), 'Invalid JSON fails validation')
        or diag("Invalid JSON validation unexpectedly passed");

    # Test malformed but valid JSON fails (missing required fields)
    ok(!validate_files(get_path('malformed_complex_mod')), 'Malformed JSON fails validation')
        or diag("Malformed JSON validation unexpectedly passed");

    # Test multiple files with one invalid fails
    ok(!validate_files(
        get_path('valid_complex_mod'), 
        get_path('invalid_complex_mod')
    ), 'Multiple files with one invalid file fails validation')
        or diag("Multiple file validation unexpectedly passed");

    # Test non-existent file fails
    ok(!validate_files(File::Spec->catfile($RealBin, 'nonexistent.json')), 
       'Non-existent file fails validation')
        or diag("Non-existent file validation unexpectedly passed");
};

done_testing();
