use strict;
use warnings;
use Test::Most 'die';
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use File::Spec;
use File::Path qw(make_path remove_tree);
use File::Copy qw(copy);

# Import modules
use KarabinerGenerator::ComplexModifications qw(
    list_available_rules
    read_rule_file
    get_rule_metadata
    validate_rule_file
);
use KarabinerGenerator::Config qw(mode get_path reset_test_environment);

# Ensure clean test environment
BEGIN {
    mode('test');
    reset_test_environment();
}

END {
    reset_test_environment();
}

# Set up clean test environment
my $fixture_dir = get_path('complex_mods_dir');

# Clean out existing directory and recreate it
remove_tree($fixture_dir) if -d $fixture_dir;
make_path($fixture_dir);

# Copy from the mockup directory
for my $test_file ('test_1.json', 'test_2.json') {
    my $src = File::Spec->catfile(get_path('config_dir'), 'assets', 'complex_modifications', $test_file);
    my $dst = File::Spec->catfile($fixture_dir, $test_file);
    copy($src, $dst) or die "Failed to copy $test_file: $!\nSource: $src\nDest: $dst";
}

# Test listing available rules
subtest 'List available rules' => sub {
    plan tests => 8;  # 4 base tests + 2 files * 2 tests each
    
    my $rules = list_available_rules($fixture_dir);
    ok($rules, 'Got rules list');
    is(ref($rules), 'ARRAY', 'Rules list is an array');
    is(scalar(@$rules), 2, 'Found all test files');
    
    # Check for specific expected files
    my @filenames = sort map { (File::Spec->splitpath($_->{file}))[2] } @$rules;
    is_deeply(\@filenames, ['test_1.json', 'test_2.json'], 'Found expected rule files');
    
    # Verify rules have correct titles and rule counts
    my %expected_titles = (
        'test_1.json' => 'Test Rule 1',
        'test_2.json' => 'Test Rule 2'
    );

    my %expected_rule_counts = (
        'test_1.json' => 1,
        'test_2.json' => 1
    );

    foreach my $rule (@$rules) {
        my $filename = (File::Spec->splitpath($rule->{file}))[2];
        is($rule->{title}, $expected_titles{$filename}, "Correct title for $filename");
        is($rule->{rules}, $expected_rule_counts{$filename}, "Correct rule count for $filename");
    }
};

# Test detailed rule processing
subtest 'Rule processing' => sub {
    plan tests => 4;
    
    # Test rule processing for test_1.json
    {
        my $file = File::Spec->catfile($fixture_dir, 'test_1.json');
        my $rule = read_rule_file($file);
        ok($rule, 'Read test_1.json successfully');
        is($rule->{title}, 'Test Rule 1', 'test_1.json title correct');
    }

    # Test rule processing for test_2.json
    {
        my $file = File::Spec->catfile($fixture_dir, 'test_2.json');
        my $rule = read_rule_file($file);
        ok($rule, 'Read test_2.json successfully');
        is($rule->{title}, 'Test Rule 2', 'test_2.json title correct');
    }
};

# Test rule metadata extraction
subtest 'Rule metadata extraction' => sub {
    plan tests => 6;
    
    for my $file ('test_1.json', 'test_2.json') {
        my $path = File::Spec->catfile($fixture_dir, $file);
        my $rule = read_rule_file($path);
        my $metadata = get_rule_metadata($rule);
        
        ok($metadata, "Got metadata for $file");
        is($metadata->{title}, $rule->{title}, "Title matches for $file");
        is(scalar(@{$metadata->{rules}}), 1, "Correct rule count for $file");
    }
};

# Test error conditions
subtest 'Error conditions' => sub {
    plan tests => 4;
    
    # Test with non-existent directory
    eval { list_available_rules('/nonexistent/dir') };
    like($@, qr/Directory does not exist/, 'Handles non-existent directory');
    
    # Test with malformed JSON (syntax error)
    throws_ok {
        read_rule_file(get_path('malformed_complex_mod'))
    } qr/Failed to parse/, 'Handles malformed JSON file';
    
    # Test with invalid Karabiner rule (valid JSON, invalid rule)
    ok(!validate_rule_file(get_path('invalid_complex_mod')), 
       'Detects invalid Karabiner rules');
    
    # Test with missing file
    throws_ok {
        read_rule_file('/nonexistent/file.json')
    } qr/File does not exist/, 'Handles missing file';
};

done_testing();