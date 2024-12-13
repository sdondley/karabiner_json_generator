# File: t/03_template.t
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use FindBin qw($RealBin);
use lib "$RealBin/../lib";
use JSON;

BEGIN { $ENV{TEST_MODE} = 1; }

use KarabinerGenerator::Template qw(process_templates);

# Create temp test environment
my $tmp_dir = tempdir(CLEANUP => 1);
mkdir "$tmp_dir/templates";
mkdir "$tmp_dir/output";

# Create test template
sub create_test_template {
    open my $fh, '>', "$tmp_dir/templates/test.json.tpl" or die $!;
    print $fh q{
{
    "title": "[% test.title %]",
    "rules": []
}
    };
    close $fh;
}

# Test template processing
subtest 'Template Processing' => sub {
    plan tests => 4;
    
    create_test_template();
    
    my $config = {
        test => {
            title => 'Test Config'
        }
    };
    
    my @files = process_templates(
        "$tmp_dir/templates",
        $config,
        "$tmp_dir/output"
    );
    
    ok(@files, 'Files generated');
    ok(-f $files[0], 'Output file exists');
    
    # Test file content
    open my $fh, '<', $files[0] or die $!;
    my $content = do { local $/; <$fh> };
    close $fh;
    
    my $json = decode_json($content);
    is($json->{title}, 'Test Config', 'Template variables processed correctly');
    is_deeply($json->{rules}, [], 'Rules array is empty as expected');
};

done_testing();