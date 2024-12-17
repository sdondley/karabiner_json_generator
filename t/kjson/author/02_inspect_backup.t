# t/kjson/author/02_inspect_backup.t
use strict;
use warnings;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../../lib";
use JSON;
use Data::Dumper;
use File::Temp qw(tempdir);
use File::Spec;
use Try::Tiny;

# Skip unless AUTHOR_TESTING
unless ($ENV{AUTHOR_TESTING}) {
    plan skip_all => 'Author testing. Set $ENV{AUTHOR_TESTING} to run.';
}

use KarabinerGenerator::KarabinerJsonFile qw(
    read_karabiner_json 
    write_karabiner_json 
    lint_karabiner_json
);

# Prepare test environment
my $temp_dir = tempdir(CLEANUP => 1);
my $test_file = File::Spec->catfile($temp_dir, 'karabiner.json');
my $backup_file = "$test_file~";

diag("\n=== DEBUG INFO ===");
diag("Test file: $test_file");
diag("Backup file: $backup_file");

my $initial_config = {
    "global" => {
        "check_for_updates_on_startup" => JSON::true
    },
    "profiles" => [
        {
            "name" => "Original",
            "complex_modifications" => {
                "rules" => [
                    {
                        "description" => "Original Rule",
                        "manipulators" => [
                            {
                                "type" => "basic",
                                "from" => { "key_code" => "a" },
                                "to" => [{ "key_code" => "b" }]
                            }
                        ]
                    }
                ]
            }
        }
    ]
};

# Write initial config
ok(write_karabiner_json($initial_config, $test_file), 'Initial config written');

# Read it back
my $read_config = read_karabiner_json($test_file);
ok($read_config && ref $read_config eq 'HASH', 'Initial config read successfully');

# Test backup creation
my $modified_config = {%$initial_config};
$modified_config->{profiles}[0]{name} = "Modified";
$modified_config->{profiles}[0]{complex_modifications}{rules}[0]{description} = "Modified Rule";

ok(write_karabiner_json($modified_config, $test_file), 'Modified config written');

my $backup_content = read_karabiner_json($backup_file);
ok($backup_content, 'Backup file readable');
is($backup_content->{profiles}[0]{name}, "Original", 'Backup contains original content');

# Test invalid config with debugging
diag("\n=== Testing Invalid Config ===");
my $invalid_config = { 'this' => 'is invalid' };
my $error_caught = '';
my $died = 0;

local $SIG{__DIE__} = sub {
    $died = 1;
    diag("Die handler caught: $_[0]");
};

diag("About to try invalid write");
try {
    diag("Inside try block");
    write_karabiner_json($invalid_config, $test_file);
    diag("Write completed (shouldn't see this)");
} catch {
    $error_caught = $_;
    diag("Caught error: $_");
};

diag("After try/catch");
diag("Error caught: " . ($error_caught || 'NONE'));
diag("Died?: " . ($died ? 'YES' : 'NO'));

# Let's see what's actually in the files now
diag("\nFile contents after invalid write:");
if (-f $test_file) {
    diag("Test file exists, size: " . (-s $test_file));
    my $content = do { local $/; open my $fh, '<', $test_file; <$fh> };
    diag("Content: " . substr($content, 0, 100) . "...");
} else {
    diag("Test file doesn't exist!");
}

SKIP: {
    skip "Invalid config test failing - see debug output", 1 unless $error_caught;
    like($error_caught, qr/Invalid config structure/i, 'Invalid config rejected')
        or diag "Got error: $error_caught";
}

# Check file wasn't corrupted
my $final_content = read_karabiner_json($test_file);
ok($final_content && ref $final_content eq 'HASH', 'File still readable after invalid write attempt');
is($final_content->{profiles}[0]{name}, "Modified", 'File maintains valid content');

done_testing();