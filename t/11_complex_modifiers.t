#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";

use KarabinerGenerator::ComplexModifiers qw(validate_complex_modifiers install_complex_modifiers);

# Create temp directory for tests
my $test_dir = tempdir(CLEANUP => 1);

# Test validation
subtest 'Complex Modifiers Validation' => sub {
    # Test valid complex modifiers file
    my $valid_json = qq{
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
    my $source = File::Spec->catfile($test_dir, "complex_modifiers.json");
    my $dest_dir = File::Spec->catfile($test_dir, "dest");
    
    # Create test file
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
    
    open my $fh, '>', $source or die "Cannot create test file: $!";
    print $fh $test_json;
    close $fh;
    
    # Test installation
    ok(install_complex_modifiers($source, $dest_dir), "Installation succeeds with valid file");
    ok(-f File::Spec->catfile($dest_dir, "complex_modifiers.json"), "File exists in destination");
    
    # Test installation with invalid destination
    ok(!install_complex_modifiers($source, "/nonexistent/path"), "Installation fails with invalid destination");
    
    # Test installation with missing source
    ok(!install_complex_modifiers("/nonexistent/file.json", $dest_dir), "Installation fails with missing source");
};

done_testing();