# File: t/11_complex_modifiers.t
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use File::Path qw(make_path);
use Cwd qw(getcwd abs_path);
use FindBin qw($RealBin);
use lib "$RealBin/../lib";

use KarabinerGenerator::ComplexModifiers qw(validate_complex_modifiers install_complex_modifiers);

# Store the original working directory
my $orig_dir = getcwd();

# Create isolated temp directory for tests
my $test_dir = tempdir(CLEANUP => 1);
chdir $test_dir or die "Cannot chdir to test directory: $!";

END {
    chdir $orig_dir if defined $orig_dir;
}

# Test validation
subtest 'Complex Modifiers Validation' => sub {
    plan tests => 3;
    local $ENV{TEST_MODE} = 1;  # Enable test mode for validation

    # Test valid complex modifiers file
    my $valid_json = qq{
        {
            "title": "Complex Modifiers",
            "rules": [
                {
                    "description": "Test Rule",
                    "manipulators": [
                        {
                            "type": "basic",
                            "from": { "key_code": "a" },
                            "to": [{ "key_code": "b" }]
                        }
                    ]
                }
            ]
        }
    };
    
    my $valid_file = File::Spec->catfile($test_dir, "valid.json");
    open my $fh, '>', $valid_file or die "Cannot create test file: $!";
    print $fh $valid_json;
    close $fh;
    
    ok(validate_complex_modifiers($valid_file), "Valid complex modifiers file passes validation");
    
    # Test invalid JSON
    my $invalid_file = File::Spec->catfile($test_dir, "invalid.json");
    open $fh, '>', $invalid_file or die "Cannot create test file: $!";
    print $fh "{ invalid json }";
    close $fh;
    
    ok(!validate_complex_modifiers($invalid_file), "Invalid JSON fails validation");
    
    # Test missing required fields
    my $missing_fields = File::Spec->catfile($test_dir, "missing_fields.json");
    open $fh, '>', $missing_fields or die "Cannot create test file: $!";
    print $fh '{"title": "Test"}';
    close $fh;
    
    ok(!validate_complex_modifiers($missing_fields), "JSON missing required fields fails validation");
};

# Test installation
subtest 'Complex Modifiers Installation' => sub {
    plan tests => 4;
    local $ENV{TEST_MODE} = 1;

    my $test_cm_file = File::Spec->catfile($test_dir, "test_complex_modifiers.json");
    my $test_dest_dir = File::Spec->catfile($test_dir, "dest");
    my $invalid_dest = "/this/path/should/not/exist/ever";  # Use a definitely invalid path
    
    # Create test file with minimal valid content
    my $test_json = qq{
        {
            "title": "Complex Modifiers",
            "rules": [
                {
                    "description": "Test Rule",
                    "manipulators": []
                }
            ]
        }
    };
    
    open my $fh, '>', $test_cm_file or die "Cannot create test file: $!";
    print $fh $test_json;
    close $fh;
    
    # Test successful installation
    ok(install_complex_modifiers($test_cm_file, $test_dest_dir), 
       "Installation succeeds with valid file");
    
    my $installed_file = File::Spec->catfile($test_dest_dir, "test_complex_modifiers.json");
    ok(-f $installed_file, "File exists in destination");
    
    # Test installation with invalid paths
    ok(!install_complex_modifiers(
        File::Spec->catfile($test_dir, "nonexistent.json"),
        $test_dest_dir
    ), "Installation fails with missing source");
    
    # Test installation with invalid destination
    ok(!install_complex_modifiers(
        $test_cm_file,
        $invalid_dest
    ), "Installation fails with invalid destination");
};

done_testing();