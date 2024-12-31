#!/usr/bin/env perl
# t/Validator/01_validator.t
use strict;
use warnings;
use Test::More;
use File::Spec;
use KarabinerGenerator::Init qw(init);

# Initialize test environment
init();

# Load modules
use_ok('KarabinerGenerator::Validator', 'validate_files')
    or BAIL_OUT("Couldn't load KarabinerGenerator::Validator");

use KarabinerGenerator::TestEnvironment::Loader qw(load_test_fixtures);

# Load test fixtures
ok(load_test_fixtures(), 'Loaded test fixtures');

subtest 'File Validation' => sub {
    # Test valid JSON passes
    ok(validate_files('newt/Validator/fixtures/01/karabiner/valid.json'), 'Valid JSON passes validation')
        or diag("Valid JSON validation failed");

    # Test invalid JSON fails
    ok(!validate_files('newt/Validator/fixtures/01/karabiner/invalid.json'), 'Invalid JSON fails validation')
        or diag("Invalid JSON validation unexpectedly passed");

    # Test malformed JSON fails
    ok(!validate_files('newt/Validator/fixtures/01/karabiner/malformed.json'), 'Malformed JSON fails validation')
        or diag("Malformed JSON validation unexpectedly passed");

    # Test multiple files with one invalid fails
    ok(!validate_files(
        'newt/Validator/fixtures/01/karabiner/valid.json',
        'newt/Validator/fixtures/01/karabiner/invalid.json'
    ), 'Multiple files with one invalid file fails validation')
        or diag("Multiple file validation unexpectedly passed");

    # Test non-existent file fails
    ok(!validate_files('newt/Validator/fixtures/01/karabiner/nonexistent.json'),
       'Non-existent file fails validation')
        or diag("Non-existent file validation unexpectedly passed");
};

done_testing();