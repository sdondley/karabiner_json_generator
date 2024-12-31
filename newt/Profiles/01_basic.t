#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use KarabinerGenerator::Init qw(init);
use KarabinerGenerator::TestEnvironment::Loader qw(
    load_project_defaults
    load_test_fixtures
);
use KarabinerGenerator::Profiles qw(
    has_profile_config
    validate_profile_config
);
use KarabinerGenerator::DebugUtils qw(db);

# Initialize test environment
init();

db("Loading project defaults...");
load_project_defaults();

db("Loading test fixtures...");
load_test_fixtures();

db("Checking for profile config...");
ok(has_profile_config(), "Profile config exists from fixtures");

db("Testing file structure:");
my $gen_json_dir = KarabinerGenerator::Config::get_path('generated_json_dir');
db("Generated JSON dir: $gen_json_dir");
if (-d $gen_json_dir) {
    db("Directory exists");
    opendir(my $dh, $gen_json_dir) or die "Can't open $gen_json_dir: $!";
    while (my $entry = readdir($dh)) {
        next if $entry eq '.' || $entry eq '..';
        db("  Found: $entry");
    }
    closedir($dh);
} else {
    db("Directory does not exist!");
}

db("Running validation...");
my $validation = validate_profile_config();
ok($validation->{valid}, "Files are valid")
    or diag "Missing files: " . join(", ", @{$validation->{missing_files}});

done_testing();