use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";
use KarabinerGenerator::Config qw(get_path mode);
use KarabinerGenerator::ComplexModifiers qw(validate_complex_modifiers install_complex_modifiers);
use Data::Dumper;

# Set test mode
mode('test');

# Debug: Print test paths
print "# Debug - Test Paths:\n";
for my $path_name (qw(valid_complex_mod invalid_complex_mod malformed_complex_mod complex_mods_dir complex_modifiers_json)) {
    my $path = get_path($path_name);
    print "# $path_name => $path\n";
    print "# File exists: " . (-f $path ? "yes" : "no") . "\n";
    if (-f $path) {
        open my $fh, '<', $path or warn "Can't read $path: $!";
        my $content = do { local $/; <$fh> };
        print "# Content:\n# ", $content, "\n";
    }
}

# Test validation
subtest 'Complex Modifiers Validation' => sub {
    plan tests => 3;

    ok(validate_complex_modifiers(get_path('valid_complex_mod')), 
       "Valid complex modifiers file passes validation");
    
    my $result = validate_complex_modifiers(get_path('invalid_complex_mod'));
    print "# Debug - Invalid JSON validation result: ", ($result ? "passed" : "failed"), "\n";
    ok(!$result, "Invalid JSON fails validation");
    
    ok(!validate_complex_modifiers(get_path('malformed_complex_mod')), 
       "Malformed JSON fails validation");
};

# Test installation
subtest 'Complex Modifiers Installation' => sub {
    plan tests => 4;
    
    my $test_cm_file = get_path('valid_complex_mod');
    my $test_dest_dir = get_path('complex_mods_dir');
    my $invalid_dest = "/this/path/should/not/exist/ever";
    
    print "# Debug - Installation paths:\n";
    print "# test_cm_file: $test_cm_file\n";
    print "# test_dest_dir: $test_dest_dir\n";
    
    ok(install_complex_modifiers($test_cm_file, $test_dest_dir), 
       "Installation succeeds with valid file");
    
    my $installed_file = File::Spec->catfile($test_dest_dir, 
        File::Basename::basename($test_cm_file));
    print "# Debug - Installed file path: $installed_file\n";
    print "# File exists: " . (-f $installed_file ? "yes" : "no") . "\n";
    
    ok(-f $installed_file, "File exists in destination");
    
    # Redirect STDERR for error cases
    {
        local *STDERR;
        open STDERR, '>', '/dev/null';
        
        ok(!install_complex_modifiers(
            File::Spec->catfile($test_dest_dir, "nonexistent.json"),
            $test_dest_dir
        ), "Installation fails with missing source");
        
        ok(!install_complex_modifiers(
            $test_cm_file,
            $invalid_dest
        ), "Installation fails with invalid destination");
    }
};

done_testing();