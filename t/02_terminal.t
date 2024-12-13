# File: t/02_terminal.t
use strict;
use warnings;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";

use KarabinerGenerator::Terminal qw(detect_capabilities fmt_print);

# Test terminal capability detection
subtest 'Terminal Capabilities' => sub {
    my ($has_color, $has_emoji) = detect_capabilities();
    ok(defined $has_color, 'Color support detection works');
    ok(defined $has_emoji, 'Emoji support detection works');
};

# Test formatted output
subtest 'Formatted Output' => sub {
    my $test_cases = [
        ['Test message', 'error', 0],
        ['Success message', 'success', 0],
        ['Warning message', 'warn', 0],
        ['Info message', 'info', 0],
        ['Forced message', 'error', 1],
    ];

    for my $case (@$test_cases) {
        my ($msg, $style, $force) = @$case;
        my $output = fmt_print($msg, $style, $force);
        ok(defined $output, "Output generated for $style style");
        like($output, qr/$msg/, "Message included in output");
    }
};

done_testing;