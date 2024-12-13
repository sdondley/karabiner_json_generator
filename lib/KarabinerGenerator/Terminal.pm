package KarabinerGenerator::Terminal;
use strict;
use warnings;
use Exporter "import";

our @EXPORT_OK = qw(detect_capabilities fmt_print);

sub detect_capabilities {
    my $has_color = 0;
    my $has_emoji = 0;

    # Check for color support
    eval {
        require Term::ANSIColor;
        Term::ANSIColor->import();
        $has_color = 1;
    };

    # Check for emoji support
    $has_emoji = 1 if $ENV{TERM_PROGRAM} && $ENV{TERM_PROGRAM} eq 'iTerm.app';
    $has_emoji = 1 if $ENV{LC_TERMINAL} && $ENV{LC_TERMINAL} eq 'iTerm2';
    $has_emoji = 1 if $ENV{ITERM_SESSION_ID};
    $has_emoji = 1 if $ENV{TERM} && $ENV{TERM} =~ /^(xterm|screen|tmux)-256color$/;

    return ($has_color, $has_emoji);
}

sub fmt_print {
    my ($text, $style, $force) = @_;

    return "" unless defined $text;
    return "" if !$force && ($ENV{QUIET} || $ENV{NO_FORMAT});

    my ($has_color, $has_emoji) = detect_capabilities();

    # Define emoji mappings with exactly two spaces after each emoji
    my %emoji_map = (
        'error'   => '❌  ',
        'success' => '✅  ',
        'warn'    => '⚠️  ',
        'info'    => 'ℹ️  ',
        'bullet'  => '•  '
    );

    # Define color mappings using Term::ANSIColor if available
    my %color_map = (
        'error'   => 'bold red',
        'success' => 'bold green',
        'warn'    => 'bold yellow',
        'info'    => 'bold blue',
        'bullet'  => 'white'
    );

    my $formatted_text = $text;

    if ($has_emoji && $style && exists $emoji_map{$style}) {
        $formatted_text = "$emoji_map{$style}$text";
    } elsif ($style) {
        # Fallback prefixes if no emoji support
        my %prefix_map = (
            'error'   => 'ERROR:  ',
            'success' => 'SUCCESS:  ',
            'warn'    => 'WARNING:  ',
            'info'    => 'INFO:  ',
            'bullet'  => '*  '
        );
        $formatted_text = "$prefix_map{$style}$text";
    }

    # Apply color if available and style is defined
    if ($has_color && $style && exists $color_map{$style}) {
        eval {
            $formatted_text = Term::ANSIColor::colored($formatted_text, $color_map{$style});
        };
    }

    return $formatted_text;
}

1;