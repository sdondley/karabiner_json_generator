use strict;
use warnings;
use Test::Most tests => 4, 'die';
use File::Spec;
use FindBin qw($RealBin);
use Capture::Tiny qw(capture capture_merged);
use Cwd qw(getcwd chdir);
use File::Basename qw(dirname);
use lib "$RealBin/../lib";
use KarabinerGenerator::Config qw(get_path mode);

sub run_with_opts {
    my ($opts) = @_;
    local $ENV{PERL5LIB} = join(':', @INC);
    
    my $orig_dir = getcwd();
    chdir $RealBin or die "Cannot chdir to test dir: $!";

    
    my $project_root = dirname($RealBin);
    my $script_path = get_path('json_generator');
    
    my $cmd = "$script_path $opts";

    my ($stdout, $stderr, $exit) = capture {
        system($cmd);
    };
    print $stderr;
    
    chdir $orig_dir or die "Cannot chdir back to original dir: $!";
    
    return {
        stdout => $stdout,
        stderr => $stderr,
        exit => $exit >> 8
    };
}

subtest 'Basic Options Parsing' => sub {
    plan tests => 2;
    my $result = run_with_opts('--help');
    is($result->{exit}, 0, 'Script runs with --help option');
    like($result->{stdout}, qr/Options:|Usage:/i, 'Help output shows options');
};


subtest 'Debug Option (-d)' => sub {
    plan tests => 3;
    my $result = run_with_opts('-d');
    like(
        $result->{stdout},
        qr/TERM(?:_PROGRAM)?:/,
        'Shows terminal information'
    );
    like(
        $result->{stdout},
        qr/(?:LC_TERMINAL|ITERM_SESSION_ID):/,
        'Shows additional terminal info'
    );
    like(
        $result->{stdout},
        qr/Color support:/,
        'Shows color support status'
    );
};

subtest 'Quiet Option (-q)' => sub {
    plan tests => 1;
    my $result = run_with_opts('-q');
    ok($result->{exit} == 0, 'Quiet mode runs without error');
};


subtest 'Install Option (-i)' => sub {
    plan tests => 1;
    my $result = run_with_opts('-i');
    ok($result->{exit} == 0, 'Install option runs without error');
};

done_testing();