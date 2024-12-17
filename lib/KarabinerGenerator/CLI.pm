package KarabinerGenerator::CLI;
use strict;
use warnings;
use Exporter "import";
use IPC::Run3;
use KarabinerGenerator::Config qw(get_path);

our @EXPORT_OK = qw(run_ke_cli_cmd);

# Main interface for running any Karabiner CLI command
sub run_ke_cli_cmd {
    my ($args) = @_;

    my $cli_path = get_path('cli_path');
    unless (-x $cli_path) {
        return {
            status => 2,
            stdout => '',
            stderr => 'Could not find karabiner_cli executable'
        };
    }

    my $cmd = [$cli_path, @$args];
    my ($stdout, $stderr);

    eval {
        run3($cmd, \undef, \$stdout, \$stderr);
    };

    if ($@) {
        return {
            status => 2,
            stdout => '',
            stderr => "Command failed: $@"
        };
    }

    my $exit_status = $? >> 8;
    $stdout //= '';
    $stderr //= '';
    chomp($stdout);
    chomp($stderr);

    return {
        status => $exit_status,
        stdout => $stdout,
        stderr => $stderr
    };
}

1;