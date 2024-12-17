use strict;
use warnings;
use Test::Most 'die';
use Test::Deep;
use Capture::Tiny qw(capture capture_merged);
use File::Temp qw(tempdir);
use File::Spec;
use File::Copy;
use File::Path qw(make_path remove_tree);
use File::Basename qw(dirname);
use Cwd qw(getcwd);
use FindBin qw($RealBin);
use lib "$RealBin/../lib";
use KarabinerGenerator::CLI qw(run_ke_cli_cmd);
use KarabinerGenerator::Config qw(get_path);

# Get script path from project root
my $project_root = dirname($RealBin);
my $script = File::Spec->catfile($project_root, 'bin', 'json_generator.pl');

sub run_script {
    my ($temp_dir, $args) = @_;
    local $ENV{PERL5LIB} = join(':', @INC);
    local $ENV{TEST_MODE} = 1;
    
    my $orig_dir = getcwd();
    chdir $temp_dir or die "Cannot chdir to temp dir: $!";
    
    my $cmd = "$^X $script " . join(' ', @$args);
    my ($stdout, $stderr, $exit) = capture {
        system($cmd);
    };
    
    chdir $orig_dir or die "Cannot chdir back to original dir: $!";
    
    return {
        stdout => $stdout,
        stderr => $stderr,
        status => $exit >> 8
    };
}

# Helper to set up test environment
sub setup_test_env {
    my ($temp_dir, $config_content) = @_;
    
    # Clean up any existing directories
    for my $dir ('templates', 'generated_json') {
        my $full_path = File::Spec->catdir($temp_dir, $dir);
        remove_tree($full_path) if -d $full_path;
    }
    
    my $template_dir = File::Spec->catdir($temp_dir, 'templates');
    my $output_dir = File::Spec->catdir($temp_dir, 'generated_json');
    make_path($template_dir, $output_dir);
    
    # Write config files
    open my $cf, '>', File::Spec->catfile($temp_dir, 'config.yaml') or die $!;
    print $cf $config_content;
    close $cf;
    
    open my $gf, '>', File::Spec->catfile($temp_dir, 'global_config.yaml') or die $!;
    print $gf "karabiner:\n  config_dir: \"$temp_dir/config\"\n";
    close $gf;
    
    # Create templates
    for my $template_name (qw(dtls dtrs lrs rls)) {
        my $template_file = File::Spec->catfile($template_dir, "app_activators_${template_name}.json.tpl");
        open my $tf, '>', $template_file or die $!;
        print $tf '{"title":"[% title %]","rules":[]}';
        close $tf;
    }
    
    # Create complex_modifiers.json
    open my $cm, '>', File::Spec->catfile($temp_dir, "complex_modifiers.json") or die $!;
    print $cm '{"title":"Complex Modifiers","rules":[]}';
    close $cm;
    
    return ($template_dir, $output_dir);
}

# Test Cases
subtest 'Standard Output Check' => sub {
    my $temp_dir = tempdir(CLEANUP => 1);
    
    my $config = q{
app_activators:
    title: "Test App Activators"
    shell_command: "/test/script.sh"
    modifiers:
        double_tap_rshift:
            apps:
                - trigger_key: "s"
                  app_name: "Safari"
    };
    
    my ($template_dir, $output_dir) = setup_test_env($temp_dir, $config);
    my $result = run_script($temp_dir, []);
    my $stdout = $result->{stdout};

    like($stdout, qr/Starting JSON generation process/i, 'Shows start message');
    like($stdout, qr/Generating JSON files from templates/i, 'Shows template processing message');
    like($stdout, qr/Validating JSON files/i, 'Shows validation step');
    like($stdout, qr/Installation skipped/i, 'Shows installation skipped message');
    
    is($result->{status}, 0, 'Script exits successfully');
};

subtest 'Quiet Output (-q)' => sub {
    my $temp_dir = tempdir(CLEANUP => 1);
    my ($template_dir, $output_dir) = setup_test_env($temp_dir, 'app_activators: {title: "Test"}');
    my $result = run_script($temp_dir, ['-q']);
    is($result->{stdout}, '', 'No output in quiet mode');
    is($result->{status}, 0, 'Exits successfully');
};

subtest 'Auto Install (-i)' => sub {
    my $temp_dir = tempdir(CLEANUP => 1);
    my ($template_dir, $output_dir) = setup_test_env($temp_dir, 'app_activators: {title: "Test"}');
    my $result = run_script($temp_dir, ['-i']);
    like($result->{stdout}, qr/Installing files/i, 'Shows installation message');
    unlike($result->{stdout}, qr/Would you like to install/i, 'No install prompt');
    is($result->{status}, 0, 'Exits successfully');
};

done_testing;