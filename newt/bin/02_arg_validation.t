use strict;
use warnings;
use Test::Most 'die';
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use File::Spec;
use KarabinerGenerator::Init qw(init db);
use KarabinerGenerator::TestEnvironment::Loader qw(load_project_defaults load_karabiner_defaults load_test_fixtures);

require "$RealBin/../../bin/json_generator.pl";

db("\n### ENTERING arg_validation test ###");
init();
load_project_defaults();
load_karabiner_defaults();

# Test cases for argument validation
my @test_cases = (
   {
       name => "enable without install flag",
       opts => { enable => 1 },
       expected_error => "-e/--enable option requires -i/--install\n",
       description => "Should error when -e used without -i"
   },
   {
       name => "profiles without install flag",
       opts => { profiles => 1 },
       expected_error => "-p/--profiles option requires -i/--install\n",
       description => "Should error when -p used without -i"
   },
   {
       name => "enable and profiles together",
       opts => { install => 1, enable => 1, profiles => 1 },
       expected_error => "Cannot use -e/--enable with -p/--profiles\n",
       description => "Should error when -e and -p used together"
   },
   {
       name => "valid enable with install",
       opts => { install => 1, enable => 1 },
       expected_error => undef,
       description => "Should accept -e with -i"
   },
   {
       name => "valid profiles with install",
       opts => { install => 1, profiles => 1 },
       expected_error => undef,
       description => "Should accept -p with -i"
   }
);

for my $test (@test_cases) {
    subtest $test->{name} => sub {
        db("\nRunning test: $test->{name}");
        
        my $result = eval {
            KarabinerGenerator::Generator->run(%{$test->{opts}});
        };
        my $error = $@;
        
        db("Error: $error") if $error;
        
        if ($test->{expected_error}) {
            is($error, $test->{expected_error}, $test->{description});
        } else {
            ok(!$error, $test->{description});
        }
    };
}



done_testing();