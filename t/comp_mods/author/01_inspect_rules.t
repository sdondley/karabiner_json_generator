# t/comp_mods/author/01_inspect_rules.t
use strict;
use warnings;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../../lib";
use JSON;
use File::Spec;
use File::Path qw(make_path remove_tree);
use File::Copy qw(copy);
use KarabinerGenerator::Config qw(mode get_path reset_test_environment);

BEGIN {
    $| = 1;
    select((select(STDOUT), $|=1)[0]);
    mode('test');  # Ensure we're in test mode
    reset_test_environment();
}

END {
    reset_test_environment();
}

# Skip unless AUTHOR_TESTING
unless ($ENV{AUTHOR_TESTING}) {
    plan skip_all => 'Author testing. Set $ENV{AUTHOR_TESTING} to run.';
}

use KarabinerGenerator::ComplexModifications qw(
    list_available_rules
    read_rule_file
    get_rule_metadata
);

# Get path and clean directory
my $FIXTURES_DIR = get_path('complex_mods_dir');
remove_tree($FIXTURES_DIR) if -d $FIXTURES_DIR;
make_path($FIXTURES_DIR);

# Copy test files
for my $test_file ('test_1.json', 'test_2.json') {
    my $src = File::Spec->catfile(get_path('config_dir'), 'assets', 'complex_modifications', $test_file);
    my $dst = File::Spec->catfile($FIXTURES_DIR, $test_file);
    copy($src, $dst) or die "Failed to copy $test_file: $!";
}

print "\nComplex Modifications Rules\n";
print "=" x 80, "\n\n";

# List all available rules
my $rules = list_available_rules($FIXTURES_DIR);

foreach my $rule (sort { $a->{file} cmp $b->{file} } @$rules) {
    my $filename = (File::Spec->splitpath($rule->{file}))[2];
    my $rule_data = read_rule_file($rule->{file});
    
    print "$filename\n";
    print "-" x length($filename), "\n";
    
    foreach my $subrule (@{$rule_data->{rules}}) {
        print "• ", $subrule->{description} || 'No description', "\n";
    }
    print "\n";
}

print "Total files: ", scalar(@$rules), "\n\n";

pass('Complex modifications inspection complete');
done_testing();