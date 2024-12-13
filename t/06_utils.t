# File: t/06_utils.t
use strict;
use warnings;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";

use KarabinerGenerator::Utils qw(expand_path);

# Test path expansion
subtest 'Path Expansion' => sub {
    local $ENV{HOME} = '/Users/testuser';
    
    is(
        expand_path('~/test'),
        '/Users/testuser/test',
        'Home directory expanded correctly'
    );
    
    is(
        expand_path('/absolute/path'),
        '/absolute/path',
        'Absolute path unchanged'
    );
};

done_testing;