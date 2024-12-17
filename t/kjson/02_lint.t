use strict;
use warnings;
use Test::Most tests => 3, 'die';
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use File::Temp qw(tempdir);
use JSON;

# Import the config module with required functions
use KarabinerGenerator::Config qw(mode get_path);

# Ensure we're in test mode
mode('test');

# Test module loading
use_ok('KarabinerGenerator::KarabinerJsonFile', qw(lint_karabiner_json));

# Test successful linting of fixture
subtest 'Successful lint' => sub {
    plan tests => 3;
    
    # Use valid_complex_mod from test paths
    my $fixture_path = get_path('valid_complex_mod');
    
    my $result = lint_karabiner_json($fixture_path);
    ok($result, 'Got a result from linting');
    is($result->{status}, 0, 'Linting successful');
    is($result->{stdout}, "$fixture_path: ok", 'Correct success message');
};

# Test failing lint
subtest 'Failed lint' => sub {
    plan tests => 4;
    
    # Use malformed_complex_mod from test paths for guaranteed JSON parse error
    my $fixture_path = get_path('malformed_complex_mod');
    
    my $result = lint_karabiner_json($fixture_path);
    ok($result, 'Got a result from linting');
    isnt($result->{status}, 0, 'Linting failed as expected');
    
    # Test either stderr has error message or stdout contains error information
    ok(
        ($result->{stderr} && $result->{stderr} =~ /error/i) ||
        ($result->{stdout} && $result->{stdout} =~ /error/i),
        'Error message present in output'
    );
    
    # Verify we got some kind of error output
    ok(
        $result->{stderr} || $result->{stdout},
        'Some output was captured'
    );
};