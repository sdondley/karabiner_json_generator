use strict;
use warnings;
use Test::Most 'die';
use File::Temp qw(tempdir);
use FindBin qw($RealBin);
use File::Spec;
use lib "$RealBin/../lib";

use KarabinerGenerator::Installer qw(install_files);
use KarabinerGenerator::Config qw(get_path mode);

# Ensure we're in test mode
mode('test');

subtest 'File Installation Basic Tests' => sub {
    plan tests => 4;
    
    # Create source test file in generated_json directory
    my $test_filename = 'test_install.json';
    my $source_file = File::Spec->catfile(get_path('generated_json_dir'), $test_filename);
    
    open my $fh, '>', $source_file or die "Cannot create test file: $!";
    print $fh "test content";
    close $fh;
    
    # Get the complex modifications directory from Config
    my $dest_dir = get_path('complex_mods_dir');
    
    # Test successful installation
    my $result = install_files($dest_dir, $source_file);
    ok($result, 'Installation completes successfully');
    
    my $dest_file = File::Spec->catfile($dest_dir, $test_filename);
    ok(-f $dest_file, 'File exists in destination');
    
    # Test file content
    open my $check_fh, '<', $dest_file or die "Cannot read installed file: $!";
    my $content = do { local $/; <$check_fh> };
    close $check_fh;
    
    is($content, "test content", 'Installed file content matches source');
    
    # Cleanup
    unlink $source_file;
    ok(!-f $source_file, 'Source file cleaned up');
};

subtest 'Complex Modifications Installation' => sub {
    plan tests => 3;
    
    # Use the complex modifications directory from Config
    my $source_file = File::Spec->catfile(get_path('generated_json_dir'), 'complex_modifiers.json');
    my $dest_dir = get_path('complex_mods_dir');
    
    # Create test file
    open my $fh, '>', $source_file or die "Cannot create test file: $!";
    print $fh '{"title": "Test Complex Modification"}';
    close $fh;
    
    ok(-f $source_file, 'Test source file exists');
    
    my $result = install_files($dest_dir, $source_file);
    ok($result, 'Complex modification file installation succeeds');
    
    my $dest_file = File::Spec->catfile($dest_dir, 'complex_modifiers.json');
    ok(-f $dest_file, 'Complex modification file exists in destination');
    
    # Cleanup
    unlink $source_file;
};

subtest 'Error Handling' => sub {
    plan tests => 3;
    
    my $dest_dir = get_path('complex_mods_dir');
    
    # Temporarily disable warnings for error condition tests
    local $SIG{__WARN__} = sub {};
    
    # Test with non-existent source file
    my $nonexistent = File::Spec->catfile(get_path('generated_json_dir'), 'nonexistent.json');
    my $result = install_files($dest_dir, $nonexistent);
    ok(!$result, 'Installation fails with non-existent source');
    
    # Test with invalid destination directory
    my $source_file = File::Spec->catfile(get_path('generated_json_dir'), 'test.json');
    open my $fh, '>', $source_file or die "Cannot create test file: $!";
    print $fh "test content";
    close $fh;
    
    $result = install_files('/this/path/should/not/exist', $source_file);
    ok(!$result, 'Installation fails with invalid destination');
    
    # Test with unreadable source file
    my $unreadable = File::Spec->catfile(get_path('generated_json_dir'), 'unreadable.json');
    open my $fh2, '>', $unreadable or die "Cannot create test file: $!";
    print $fh2 "test content";
    close $fh2;
    chmod 0000, $unreadable;
    
    $result = install_files($dest_dir, $unreadable);
    ok(!$result, 'Installation fails with unreadable source');
    
    # Cleanup
    chmod 0644, $unreadable;
    unlink $unreadable;
    unlink $source_file;
};

subtest 'Multiple File Installation' => sub {
    plan tests => 4;
    
    my $dest_dir = get_path('complex_mods_dir');
    
    # Create multiple test files
    my @test_files;
    for my $i (1..3) {
        my $filename = "test_$i.json";
        my $filepath = File::Spec->catfile(get_path('generated_json_dir'), $filename);
        open my $fh, '>', $filepath or die "Cannot create test file: $!";
        print $fh "content $i";
        close $fh;
        push @test_files, $filepath;
    }
    
    my $result = install_files($dest_dir, @test_files);
    ok($result, 'Multiple file installation succeeds');
    
    # Check all files were installed
    for my $i (1..3) {
        my $installed = File::Spec->catfile($dest_dir, "test_$i.json");
        ok(-f $installed, "File $i exists in destination");
    }
    
    # Cleanup
    unlink @test_files;
};

done_testing();