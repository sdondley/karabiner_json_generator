# newt/Cleaner/01_basic.t - Test finding and cleaning generated JSON files
use strict;
use warnings;
use Test::Most 'die';
use File::Spec;
use File::Path qw(make_path);
use File::Basename qw(dirname basename);
use KarabinerGenerator::Config qw(get_path);
use KarabinerGenerator::Init qw(init db dbd);
use KarabinerGenerator::TestEnvironment::Loader qw(load_project_defaults);
use File::Find;

# Initialize test environment
init();
load_project_defaults();

# Get paths and verify
my $generated_json_dir = get_path('generated_json_dir');
my $project_dir = get_path('project_dir');
my $output_dir = get_path('output_dir');

db("Path information:");
db("  Generated JSON dir: $generated_json_dir");
db("  Base directory name: " . basename($generated_json_dir));

ok(-d $generated_json_dir, "Generated JSON directory exists") 
    or diag("Generated JSON dir $generated_json_dir does not exist");

# Create test file structure
my @test_files = (
    'test1.json',
    'test2.json',
    'subdir/test3.json',
    'subdir/test4.json'
);

my @hidden_files = (
    '.hidden.json',
    '.hidden_dir/test5.json'
);

# Create test files
for my $file (@test_files) {
    my $path = File::Spec->catfile($generated_json_dir, $file);
    my $dir = dirname($path);
    db("Creating directory: $dir");
    make_path($dir) unless -d $dir;
    db("Creating file: $path");
    open my $fh, '>', $path or die "Cannot create $path: $!";
    print $fh "{}";  # Empty JSON object
    close $fh;
    die "Failed to create test file $path" unless -f $path;
}

# Create hidden files/directories
for my $file (@hidden_files) {
    my $path = File::Spec->catfile($generated_json_dir, $file);
    my $dir = dirname($path);
    db("Creating hidden directory: $dir");
    make_path($dir) unless -d $dir;
    db("Creating hidden file: $path");
    open my $fh, '>', $path or die "Cannot create $path: $!";
    print $fh "{}";  # Empty JSON object
    close $fh;
}

# Debug the created structure
db("\nVerifying created files:");
File::Find::find(
    {
        wanted => sub {
            my $file = $File::Find::name;
            db("  Found: $file") if -f;
        },
        no_chdir => 1
    },
    $generated_json_dir
);

# Test finding JSON files
require_ok('KarabinerGenerator::Cleaner');

# Get and debug files found
my @found_files = KarabinerGenerator::Cleaner::find_generated_files();
db("\nFound " . scalar(@found_files) . " files via find_generated_files():");
for my $file (@found_files) {
    db("  Found: $file");
}

# Verify file count
is(scalar @found_files, scalar @test_files, "Found correct number of files")
    or diag("Expected " . scalar(@test_files) . " files but found " . scalar(@found_files) . 
           "\nFound files: " . join("\n", @found_files));

# Check that each test file was found
for my $test_file (@test_files) {
    my $full_path = File::Spec->catfile($generated_json_dir, $test_file);
    ok(grep { $_ eq $full_path } @found_files, "Found $test_file")
        or diag("Could not find expected file: $full_path");
}

# Check that hidden files were not found
for my $hidden_file (@hidden_files) {
    my $full_path = File::Spec->catfile($generated_json_dir, $hidden_file);
    ok(!grep { $_ eq $full_path } @found_files, "Did not find hidden file $hidden_file");
}

done_testing();