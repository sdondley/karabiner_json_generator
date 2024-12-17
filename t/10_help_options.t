# File: t/10_help_options.t
use strict;
use warnings;
use Test::Most 'die';
use Capture::Tiny qw(capture);
use FindBin qw($RealBin);
use File::Spec;
use lib "$RealBin/../lib";
use IO::Pty;

# Path to the main script
my $script_path = File::Spec->catfile($RealBin, '..', 'bin', 'json_generator.pl');

# Verify script exists
plan skip_all => "Script not found at $script_path" unless -f $script_path;

# Make script executable
chmod 0755, $script_path;

# Helper to run script with PTY (consistent with 09_cli_output.t)
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
        exec($^X, $script_path, @$args) or die "Exec failed: $!";
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
    
    $output =~ s/^[yn]\n//;  # Clean PTY output
    $output =~ s/^\s+|\s+$//g;
    
    return {
        stdout => $output,
        stderr => '',
        exit => $exit_status
    };
}

# Test help option
subtest 'Help Option Tests' => sub {
    my $result = run_script_with_pty(['-h']);
    
    is($result->{exit}, 0, 'Help option exits with 0');
    like(
        $result->{stdout}, 
        qr/Usage:|Options:/i,
        'Help output contains usage information'
    );
    like(
        $result->{stdout},
        qr/-h.*help/i,
        'Help output describes -h option'
    );
    like(
        $result->{stdout},
        qr/-d.*debug/i,
        'Help output describes -d option'
    );
    like(
        $result->{stdout},
        qr/-i.*install/i,
        'Help output describes -i option'
    );
    like(
        $result->{stdout},
        qr/-q.*quiet/i,
        'Help output describes -q option'
    );
};

# Test invalid option
subtest 'Invalid Option Tests' => sub {
    my $result = run_script_with_pty(['--invalid-option']);
    
    isnt($result->{exit}, 0, 'Invalid option exits with non-zero');
    like(
        $result->{stdout},
        qr/Unknown option:|Usage:/i,
        'Invalid option shows usage information'
    );
};

done_testing();