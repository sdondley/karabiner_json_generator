# File: t/08_options.t
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Capture::Tiny qw(capture capture_merged);
use FindBin qw($RealBin);
use File::Spec;
use lib "$RealBin/../lib";

# Path to the main script
my $script_path = File::Spec->catfile($RealBin, '..', 'bin', 'json_generator.pl');

# Helper function to run script with options
sub run_with_opts {
    my ($opts) = @_;
    local $ENV{PERL5LIB} = join(':', @INC);
    
    # Always provide 'n' to the prompt to avoid hanging
    my $cmd = "echo 'n' | $^X $script_path $opts";
    
    my ($stdout, $stderr, $exit) = capture {
        system($cmd);
    };
    return {
        stdout => $stdout,
        stderr => $stderr,
        exit => $exit >> 8
    };
}

# Create test environment
my $temp_dir = tempdir(CLEANUP => 1);

subtest 'Basic Options Parsing' => sub {
    my $result = run_with_opts('');
    is($result->{exit}, 0, 'Script runs without options');
};

subtest 'Debug Option (-d)' => sub {
    my $result = run_with_opts('-d');
    like(
        $result->{stdout},
        qr/Debug Mode Enabled/i,
        'Shows debug mode enabled message'
    );
    like(
        $result->{stdout},
        qr/Terminal Capabilities/i,
        'Shows terminal capabilities'
    );
    like(
        $result->{stdout},
        qr/Color support|Emoji support/i,
        'Shows support information'
    );
};

subtest 'Quiet Option (-q)' => sub {
    my $verbose = run_with_opts('');
    my $quiet = run_with_opts('-q');
    
    # Quiet mode should produce no output
    is($quiet->{stdout}, '', 'Quiet mode produces no output');
    
    # Verbose mode should have output
    isnt($verbose->{stdout}, '', 'Normal mode produces output');
};

subtest 'Install Option (-i)' => sub {
    my $result = run_with_opts('-i');
    like(
        $result->{stdout},
        qr/Installing/i,
        'Shows installation messages'
    );
};

subtest 'Option Combinations' => sub {
    # Test quiet install
    my $quiet_install = run_with_opts('-q -i');
    is($quiet_install->{stdout}, '', 'Quiet install shows no output');
    is($quiet_install->{exit}, 0, 'Quiet install exits successfully');
    
    # Test debug install
    my $debug_install = run_with_opts('-d -i');
    like(
        $debug_install->{stdout},
        qr/Debug Mode Enabled.*Installing/is,
        'Debug install shows debug info and install status'
    );
};

done_testing();