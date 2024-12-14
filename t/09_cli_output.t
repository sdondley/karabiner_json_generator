# File: t/09_cli_output.t
use strict;
use warnings;
use Test::More;
use Test::Deep;
use Capture::Tiny qw(capture capture_merged);
use File::Temp qw(tempdir);
use File::Spec;
use File::Copy;
use File::Path qw(make_path remove_tree);
use Cwd qw(getcwd);
use FindBin qw($RealBin);
use lib "$RealBin/../lib";
use IO::Pty;

# Verify scripts exist before starting tests
my $script = File::Spec->catfile($RealBin, '..', 'bin', 'json_generator.pl');
plan skip_all => "Script not found at $script" unless -f $script;

# Make script executable
chmod 0755, $script;

# Create test environment
my $temp_dir = tempdir(CLEANUP => 1);

# Helper to clean PTY output
sub clean_pty_output {
    my ($output) = @_;
    $output =~ s/^[yn]\n//;
    $output =~ s/^\s+|\s+$//g;
    return $output;
}

# Helper to run script with PTY
sub run_script_with_pty {
    my ($args, $input) = @_;
    
    my $pty = IO::Pty->new;
    my $pid = fork();
    
    if (!defined $pid) {
        die "Fork failed: $!";
    }
    
    if ($pid == 0) {  # Child
        local $ENV{PERL5LIB} = join(':', @INC);
        close STDIN;
        $pty->make_slave_controlling_terminal();
        my $slave = $pty->slave();
        open(STDIN, "<&", $slave) or die "Couldn't reopen STDIN: $!";
        open(STDOUT, ">&", $slave) or die "Couldn't reopen STDOUT: $!";
        open(STDERR, ">&", $slave) or die "Couldn't reopen STDERR: $!";
        close $pty;
        exec($^X, $script, @$args) or die "Exec failed: $!";
    }
    
    if ($input) {
        sleep(1);
        print $pty $input;
    }
    
    my $output = '';
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm(10);
        while (1) {
            my $buf;
            my $bytes = sysread($pty, $buf, 1024);
            last if !defined $bytes || $bytes == 0;
            $output .= $buf;
        }
        alarm(0);
    };
    alarm(0);
    
    waitpid($pid, 0);
    my $exit_status = $? >> 8;
    close $pty;
    
    return {
        stdout => clean_pty_output($output),
        stderr => '',
        exit => $exit_status
    };
}

# Helper to set up test environment
sub setup_test_env {
    my ($config_content) = @_;
    
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
    
    my ($template_dir, $output_dir) = setup_test_env($config);
    my $output = run_script_with_pty([], "n\n");
    my $stdout = $output->{stdout};

    # Check key semantic elements based on actual output
    like($stdout, qr/Starting JSON generation process/i, 'Shows start message');
    like($stdout, qr/Generating JSON files from templates/i, 'Shows template processing message');
    like($stdout, qr/Validating JSON files/i, 'Shows validation step');
    like($stdout, qr/All files passed validation/i, 'Shows validation result');
    like($stdout, qr/Would you like to install/i, 'Shows install prompt');
    
    # Basic ordering check
    my $start_pos = index($stdout, 'Starting');
    my $generating_pos = index($stdout, 'Generating');
    my $validating_pos = index($stdout, 'Validating');
    my $install_pos = index($stdout, 'install');
    
    ok($start_pos >= 0, 'Start message exists');
    ok($generating_pos >= 0, 'Generating message exists');
    ok($validating_pos >= 0, 'Validation message exists');
    ok($install_pos >= 0, 'Install message exists');
    
    ok($start_pos < $generating_pos, 'Generation happens after start');
    ok($generating_pos < $validating_pos, 'Validation happens after generation');
    ok($validating_pos < $install_pos, 'Install prompt comes last');
    
    is($output->{exit}, 0, 'Script exits successfully');
};

subtest 'Quiet Output (-q)' => sub {
    my ($template_dir, $output_dir) = setup_test_env('app_activators: {title: "Test"}');
    my $output = run_script_with_pty(['-q'], "n\n");
    is($output->{stdout}, '', 'No output in quiet mode');
    is($output->{exit}, 0, 'Exits successfully');
};

subtest 'Auto Install (-i)' => sub {
    my ($template_dir, $output_dir) = setup_test_env('app_activators: {title: "Test"}');
    my $output = run_script_with_pty(['-i']);
    like($output->{stdout}, qr/Installing files/i, 'Shows installation message');
    unlike($output->{stdout}, qr/Would you like to install/i, 'No install prompt');
    is($output->{exit}, 0, 'Exits successfully');
};

done_testing;