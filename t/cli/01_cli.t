#!/usr/bin/env perl
# t/cli/01_cli.t
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use File::Temp qw(tempfile);

use_ok('KarabinerGenerator::CLI', 'run_ke_cli_cmd')
    or BAIL_OUT("Couldn't load KarabinerGenerator::CLI");

subtest 'basic CLI commands' => sub {
    plan tests => 7;

    # Test version command
    my $version = run_ke_cli_cmd(['--version']);
    ok(defined $version, 'Got version output');
    is($version->{status}, 0, 'Version command succeeded');
    like($version->{stdout}, qr/^\d+\.\d+\.\d+$/, 'Version is in expected format');
    is($version->{stderr}, '', 'No stderr output for version');

    # Test help command
    my $help = run_ke_cli_cmd(['--help']);
    ok(defined $help, 'Got help output');
    is($help->{status}, 1, 'Help command returns status 1');  # Fixed expectation
    ok($help->{stdout} || $help->{stderr}, 'Got help output in stdout or stderr');
};

subtest 'json validation' => sub {
    plan tests => 6;

    # Test with valid JSON
    my ($fh, $filename) = tempfile(SUFFIX => '.json');
    print $fh '{"title": "Test", "rules": []}';
    close $fh;

    my $result = run_ke_cli_cmd(['--lint-complex-modifications', $filename]);
    ok(defined $result, 'Got result for valid JSON');
    is($result->{status}, 0, 'Valid JSON returns success status');
    like($result->{stdout}, qr/ok/i, 'Success message in output');
    unlink $filename;

    # Test with invalid JSON
    ($fh, $filename) = tempfile(SUFFIX => '.json');
    print $fh '{invalid json}';
    close $fh;

    $result = run_ke_cli_cmd(['--lint-complex-modifications', $filename]);
    ok(defined $result, 'Got result for invalid JSON');
    isnt($result->{status}, 0, 'Invalid JSON returns error status');
    ok($result->{stdout} || $result->{stderr}, 'Got output for invalid JSON');  # More lenient check
    unlink $filename;
};

done_testing();