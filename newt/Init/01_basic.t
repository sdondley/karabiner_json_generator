# 01_basic.t
use strict;
use warnings;
use Test::Most 'die';
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use File::Spec;

use KarabinerGenerator::Init qw(
    init
    is_test_mode
    db
);

db("\n### STARTING TESTS ###");
db("HARNESS_ACTIVE = " . ($ENV{HARNESS_ACTIVE} // "undef"));

# Test mode detection first, before any initialization
subtest 'Environment mode detection' => sub {
    # Production mode first
    {
        local $ENV{HARNESS_ACTIVE};  # Just unset it completely
        delete $ENV{HARNESS_ACTIVE}; 
        no warnings 'once';
        local $KarabinerGenerator::Init::TEST_MODE = undef;
        ok(!is_test_mode(), 'Correctly identifies production mode');
    }
    
    # Test mode second  
    {
        local $ENV{HARNESS_ACTIVE} = 1;  # Set it explicitly
        no warnings 'once';
        local $KarabinerGenerator::Init::TEST_MODE = undef;
        ok(is_test_mode(), 'Correctly identifies test mode');
    }
    
    # Verify caching behavior
    {
        ok(is_test_mode(), 'Initial test mode set');
        local $ENV{HARNESS_ACTIVE} = 0;
        ok(is_test_mode(), 'Mode remains cached even if ENV changes');
    }
};

# Basic initialization tests
subtest 'Basic initialization' => sub {
    # Test mode initialization only - skip production mode test
    {
        local $ENV{HARNESS_ACTIVE} = 1;
        no warnings 'once';
        local $KarabinerGenerator::Init::TEST_MODE = undef;
        local $KarabinerGenerator::Init::INITIALIZED = 0;
        local $KarabinerGenerator::Init::SKIP_TEST_INIT = 0;
        lives_ok { init() } 'Can initialize in test mode';
    }

    # Verify that we don't double-initialize
    ok(init(), 'Init returns success on subsequent calls without reinitializing');
};

# Test error conditions
subtest 'Error conditions' => sub {
    no warnings 'once';
    {
        db("\n### Setting up error test ###");
        db("About to set TEST_MODE = undef");
        local $KarabinerGenerator::Init::TEST_MODE = undef;
        db("About to set INITIALIZED = 0"); 
        local $KarabinerGenerator::Init::INITIALIZED = 0;
        db("About to set SKIP_TEST_INIT = 1");
        local $KarabinerGenerator::Init::SKIP_TEST_INIT = 1;
        db("About to set FORCE_HOME = /nonexistent/directory");
        local $KarabinerGenerator::Config::FORCE_HOME = '/nonexistent/directory';

        db("Values after setting:");
        db("TEST_MODE = " . (defined $KarabinerGenerator::Init::TEST_MODE ? $KarabinerGenerator::Init::TEST_MODE : "undef"));
        db("INITIALIZED = $KarabinerGenerator::Init::INITIALIZED");
        db("SKIP_TEST_INIT = $KarabinerGenerator::Init::SKIP_TEST_INIT");
        db("FORCE_HOME = " . (defined $KarabinerGenerator::Config::FORCE_HOME ? $KarabinerGenerator::Config::FORCE_HOME : "undef"));
        
        db("About to call init()");
        throws_ok { init(required => 1) }
            qr/Could not determine home directory/,  # Updated to match Config.pm's error
            'Init fails when environment is not valid and required = 1';
        db("After init() call");
    }
};

done_testing();