use strict;
use warnings;
use Test::Most tests => 3, 'die';
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use File::Spec;
use JSON;
use File::Path qw(make_path remove_tree);
use File::Copy qw(copy);

# Test module loading
use_ok('KarabinerGenerator::ComplexModifications', qw(
    collect_all_rules
));
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
my $complex_mods_dir = get_path('complex_mods_dir');

# Clean out existing directory and recreate it
remove_tree($complex_mods_dir) if -d $complex_mods_dir;
make_path($complex_mods_dir);

# Copy only the test files we need
for my $test_file ('test_1.json', 'test_2.json') {
    my $src = File::Spec->catfile(get_path('config_dir'), 'assets', 'complex_modifications', $test_file);
    my $dst = File::Spec->catfile($complex_mods_dir, $test_file);
    copy($src, $dst) or die "Failed to copy $test_file: $!\nSource: $src\nDest: $dst";
}

# Test collecting all rules
subtest 'Collect all rules' => sub {
    plan tests => 6;
    
    my $rules = collect_all_rules($complex_mods_dir);
    ok($rules, 'Got collected rules');
    is(ref($rules), 'ARRAY', 'Rules is an array');
    
    # We have 2 rules total (one from each file)
    is(scalar(@$rules), 2, 'Found all test rules');
    
    # Check structure of collected rules (these should be the inner rules)
    my @descriptions = sort map { $_->{description} } @$rules;
    is_deeply(\@descriptions, 
        ['Test Rule 1 Description', 'Test Rule 2 Description'], 
        'Found expected rules in collection');
    
    ok(exists $rules->[0]{description}, 'First rule has description');
    ok(exists $rules->[1]{description}, 'Second rule has description');
};

# Test error conditions
subtest 'Error conditions' => sub {
    plan tests => 2;
    
    # Test with non-existent directory
    eval { collect_all_rules('/nonexistent/dir') };
    like($@, qr/Directory does not exist/, 'Handles non-existent directory');
    
    # Test with invalid directory path
    eval { collect_all_rules('') };
    like($@, qr/Directory not specified/, 'Handles empty directory path');
};