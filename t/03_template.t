use strict;
use warnings;
use Test::Most 'die';
use FindBin qw($RealBin);
use lib "$RealBin/../lib";
use JSON;
use File::Spec;

use KarabinerGenerator::Template qw(process_templates);
use KarabinerGenerator::Config qw(get_path mode);

# Ensure we're in test mode
mode('test');

# Create test template
sub create_test_template {
    my $template_file = File::Spec->catfile(get_path('templates_dir'), 'test.json.tpl');
    open my $fh, '>', $template_file or die "Cannot create template: $!";
    print $fh q{
{
    "title": "[% test.title %]",
    "rules": []
}
    };
    close $fh;
    return $template_file;
}

# Test template processing
subtest 'Template Processing' => sub {
    plan tests => 4;
    
    my $template_file = create_test_template();
    
    my $config = {
        test => {
            title => 'Test Config'
        }
    };
    
    my @files = process_templates(
        get_path('templates_dir'),
        $config,
        get_path('generated_json_dir')
    );
    
    ok(@files, 'Files generated');
    
    # Find our specific test output file
    my $test_output_file = File::Spec->catfile(get_path('generated_json_dir'), 'test.json');
    ok(-f $test_output_file, 'Output file exists');
    
    # Test file content
    open my $fh, '<', $test_output_file or die $!;
    my $content = do { local $/; <$fh> };
    close $fh;
    
    my $json = decode_json($content);
    is($json->{title}, 'Test Config', 'Template variables processed correctly');
    is_deeply($json->{rules}, [], 'Rules array is empty as expected');
};

done_testing();