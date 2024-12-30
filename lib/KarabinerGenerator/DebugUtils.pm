# DebugUtils.pm
package KarabinerGenerator::DebugUtils;

use strict;
use warnings;
use Exporter 'import';
use Text::Wrap qw(wrap);
use File::Basename qw(basename);
use Data::Dumper;

our @EXPORT_OK = qw(db dbd);

# Width settings for output formatting
use constant {
    BRACKET_WIDTH => 25,     # Width for the bracketed section [module:line]
    LINE_WIDTH   => 120,     # Total width for message wrapping
    INDENT_WIDTH => 30,      # Width of indentation for wrapped lines
};

# ANSI color codes
use constant {
    CYAN    => "\e[36m",
    RESET   => "\e[0m",
};

# Debug state tracking
my $first_debug = 1;
my $last_test_file;
my $last_timestamp = 0;
my $last_message_type;
my $last_module;
my $last_line_was_prove_output = 0;

# Helper to trim whitespace
sub trim {
    my $str = shift;
    $str =~ s/^\s+|\s+$//g;
    return $str;
}

# Helper function to check if file should be debugged based on pattern
sub _should_debug_file {
    my ($file, $debug_str) = @_;
    return 1 if $debug_str eq '1';  # Debug everything if debug=1
    return 0 unless $debug_str && $file;

    # Get canonical names
    my $is_test = $file =~ /\.t$/;
    my $module_name = $file;
    $module_name =~ s{.*/([^/]+?)\.(pm|t|pl)$}{$1};

    # Split patterns and trim
    my @patterns = map { trim($_) } split /\|/, $debug_str;

    for my $pattern (@patterns) {
        # Handle 't' pattern specially
        if ($pattern eq 't') {
            return 1 if $is_test;
            next;
        }

        # For module patterns, require exact match
        if ($module_name eq $pattern) {
            return 1;
        }
    }

    return 0;
}

# Helper to determine if message needs a preceding newline
sub _needs_newline {
    my ($file, $msg, $module) = @_;

    # Always add newline for first debug message
    return 1 if $first_debug;

    # Add newline before section headers
    return 1 if $msg =~ /^###\s+ENTERING/;

    # Add newline when switching modules
    return 1 if defined $last_module && $module ne $last_module;

    # Add newline if the last line was prove test output
    return 1 if $last_line_was_prove_output;

    # Add newline before certain types of messages
    my $current_type = _get_message_type($msg);
    if ($current_type && $current_type eq 'test_start') {
        return 1;
    }

    return 0;
}

# Helper to determine if message needs a following newline
sub _needs_following_newline {
    my ($msg, $module) = @_;

    # Add newline after section endings
    return 1 if $msg =~ /returning \d+$/;

    # Add newline after certain result messages
    return 1 if $msg =~ /^(Done|Completed|Finished|valid: (YES|NO))$/i;

    return 0;
}

# Helper to categorize message types
sub _get_message_type {
    my ($msg) = @_;

    return 'test_start' if $msg =~ /^Testing|^Starting test/i;
    return 'section_header' if $msg =~ /^={3,}|^#{3,}/;
    return 'entering_func' if $msg =~ /^ENTERING|^Beginning|^Starting/i;
    return 'checking' if $msg =~ /^Checking|^Verifying/i;
    return 'result' if $msg =~ /^Result|^Done|^Finished|^Completed|valid: (YES|NO)$/i;

    return;
}

# Helper to detect prove test output lines
sub _is_prove_output {
    my ($line) = @_;
    return $line =~ /\.t \.*\s*\d+\/\?/;
}

sub db {
    my ($msg, $caller_level) = @_;
    my $debug = $ENV{DB} || $ENV{DEBUG} || '';
    return unless $debug;

    my (undef, $file, $line) = caller($caller_level // 0);
    return unless $file;

    # First debug call setup
    if ($first_debug) {
#        print STDERR "\nDEBUG VARS:\n";
#        print STDERR "  \$0: $0\n";
#        print STDERR "  args: $ENV{TAP_HARNESS_ARGS}\n";
#        print STDERR "  HARNESS_ACTIVE: " . ($ENV{HARNESS_ACTIVE} // 'undef') . "\n";
#        print STDERR "  debug: $debug\n\n";
        $first_debug = 0;
    }

    # Extract module/test name from file path
    my $module = $file;
    #$module =~ s{.*/([^/]+?)\.(pm|t)$}{$1};
    $module = basename($module);

    # Under prove
    if ($ENV{HARNESS_ACTIVE}) {
        my $args = $ENV{TAP_HARNESS_ARGS} // '';

        # For specific test runs, check if this is the target test
        if ($args =~ /\b(\S+\.t)$/) {
            my $target_test = $1;
            return unless $file =~ /\Q$target_test\E$/ || _should_debug_file($file, $debug);
        }
        # For directory runs, just check debug pattern
        else {
            return unless _should_debug_file($file, $debug);
        }
    }
    # Not under prove - just check debug pattern
    else {
        return unless _should_debug_file($file, $debug);
    }

    # Check if we need a newline before this message
    print STDERR "\n" if _needs_newline($file, $msg, $module);

    # Format and print debug message
    my $bracketed = sprintf("%-*s", BRACKET_WIDTH, "[$module:$line]");
    $msg ||= '(no message)';

    local $Text::Wrap::columns = LINE_WIDTH;
    local $Text::Wrap::huge = 'wrap';
    my $indentation = ' ' x INDENT_WIDTH;
    my $wrapped_msg = wrap('', $indentation, $msg);

    # Print the message
    print STDERR CYAN . $bracketed . RESET . " " . $wrapped_msg . "\n";

    # Add following newline if needed
    print STDERR "\n" if _needs_following_newline($msg, $module);

    # Update state
    $last_test_file = $file if $file =~ /\.t$/;
    $last_module = $module;
    $last_message_type = _get_message_type($msg);
    $last_line_was_prove_output = _is_prove_output($msg);
}

sub dbd {
    my ($label, $data) = @_;

    # Configure Data::Dumper
    local $Data::Dumper::Sortkeys = 1;     # Sort hash keys
    local $Data::Dumper::Indent = 1;       # Nice indentation
    local $Data::Dumper::Terse = 1;        # Don't output variable name
    local $Data::Dumper::Useqq = 1;        # Use double quotes for strings
    local $Data::Dumper::Deparse = 1;      # Handle code references

    # Format the data
    my $dump = Dumper($data);
    chomp $dump;

    # Call db with formatted message
    db($label . ":\n" . $dump, 1);
}

1;