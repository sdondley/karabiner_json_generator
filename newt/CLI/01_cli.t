#!/usr/bin/env perl
# t/CLI/01_cli.t
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use KarabinerGenerator::Init qw(init);

# Initialize test environment
init();

use_ok('KarabinerGenerator::CLI', 'run_ke_cli_cmd')
    or BAIL_OUT("Couldn't load KarabinerGenerator::CLI");

use KarabinerGenerator::TestEnvironment::Loader qw(load_test_fixtures);

# Load test fixtures
ok(load_test_fixtures(), 'Loaded test fixtures');

subtest 'basic CLI commands' => sub {
    # Test version command
    my $version = run_ke_cli_cmd(['--version']);
    ok(defined $version, 'Got version output');
    is($version->{status}, 0, 'Version command succeeded');
    like($version->{stdout}, qr/^\d+\.\d+\.\d+$/, 'Version is in expected format');
    is($version->{stderr}, '', 'No stderr output for version');

    # Test help command
    my $help = run_ke_cli_cmd(['--help']);
    ok(defined $help, 'Got help output');
    is($help->{status}, 1, 'Help command returns status 1');
    ok($help->{stdout} || $help->{stderr}, 'Got help output in stdout or stderr');
};

subtest 'json validation' => sub {
    # Test with valid JSON
    my $result = run_ke_cli_cmd(['--lint-complex-modifications', 'newt/CLI/fixtures/01/karabiner/valid.json']);
    ok(defined $result, 'Got result for valid JSON');
    is($result->{status}, 0, 'Valid JSON returns success status');
    like($result->{stdout}, qr/ok/i, 'Success message in output');

    # Test with invalid JSON
    $result = run_ke_cli_cmd(['--lint-complex-modifications', 'newt/CLI/fixtures/01/karabiner/invalid.json']);
    ok(defined $result, 'Got result for invalid JSON');
    isnt($result->{status}, 0, 'Invalid JSON returns error status');
    ok($result->{stdout} || $result->{stderr}, 'Got output for invalid JSON');

    # Test with malformed JSON
    $result = run_ke_cli_cmd(['--lint-complex-modifications', 'newt/CLI/fixtures/01/karabiner/malformed.json']);
    ok(defined $result, 'Got result for malformed JSON');
    isnt($result->{status}, 0, 'Malformed JSON returns error status');
    ok($result->{stdout} || $result->{stderr}, 'Got output for malformed JSON');
};

done_testing();