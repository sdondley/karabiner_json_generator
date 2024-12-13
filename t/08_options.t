# File: t/08_options.t
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Capture::Tiny qw(capture capture_merged);
use FindBin qw($RealBin);
use lib "$RealBin/../lib";

# Path to the main script
my $script_path = File::Spec->catfile($RealBin, '..', 'bin', 'json_generator.pl');

# Test environment setup
my $temp_dir = tempdir(CLEANUP => 1);

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

subtest 'Basic Options Parsing' => sub {
    # Test no options
    my $result = run_with_opts('');
    is($result->{exit}, 0, 'Script runs without options');
    
    # Skip help test since help isn't implemented yet
    # We could add it later when help is implemented
};

subtest 'Debug Option (-d)' => sub {
    my $result = run_with_opts('-d');
    like(
        $result->{stdout}, 
        qr/Terminal debug info|Color support|Emoji support/i, 
        'Debug output shows terminal info'
    );
};

subtest 'Quiet Option (-q)' => sub {
    my $verbose = run_with_opts('');
    my $quiet = run_with_opts('-q');
    
    ok(
        length($quiet->{stdout}) < length($verbose->{stdout}),
        'Quiet mode produces less output'
    );
};

subtest 'Install Option (-i)' => sub {
    my $test_dir = File::Spec->catdir($temp_dir, 'test_install');
    local $ENV{KARABINER_CONFIG_DIR} = $test_dir;
    
    my $result = run_with_opts('-i');
    
    like(
        $result->{stdout},
        qr/install|installing|installed/i,
        'Install option triggers installation messages'
    );
};

subtest 'Option Combinations' => sub {
    my $result = run_with_opts('-q -i');
    is($result->{exit}, 0, 'Quiet install runs successfully');
    
    $result = run_with_opts('-d -i');
    like(
        $result->{stdout},
        qr/debug|installing/i,
        'Debug install shows appropriate output'
    );
};

subtest 'Invalid Options' => sub {
    my $result = run_with_opts('--invalid-option');
    isnt($result->{exit}, 0, 'Invalid option causes error exit');
    like(
        $result->{stderr},
        qr/error|invalid|unknown/i,
        'Invalid option produces error message'
    );
};

subtest 'Environment Variable Interaction' => sub {
    local $ENV{QUIET} = 1;
    my $result = run_with_opts('-q');  # Use -q to ensure quiet mode
    unlike(
        $result->{stdout},
        qr/Starting JSON generation process/,
        'QUIET env var + -q suppresses standard output'
    );
};

done_testing;