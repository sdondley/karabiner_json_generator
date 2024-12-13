#!/usr/bin/env perl

=head1 NAME

json_generator.pl - Generate Karabiner-Elements JSON configuration files

=head1 SYNOPSIS

json_generator.pl [options]

 Options:
   -h, --help     Show this help message
   -d, --debug    Enable debug output
   -i, --install  Automatically install after generation
   -q, --quiet    Minimize output messages

=head1 DESCRIPTION

This script generates JSON configuration files for Karabiner-Elements from YAML templates.
It can validate the generated files and optionally install them into your Karabiner-Elements
configuration directory.

=cut

use strict;
use warnings;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";
use Getopt::Long qw(:config bundling no_ignore_case);
use Pod::Usage;
use File::Basename;
use File::Spec;

use KarabinerGenerator::Config qw(load_config get_paths);
use KarabinerGenerator::Terminal qw(detect_capabilities fmt_print);
use KarabinerGenerator::Template qw(process_templates);
use KarabinerGenerator::Validator qw(validate_files);
use KarabinerGenerator::Installer qw(install_files);
use KarabinerGenerator::ComplexModifiers qw(validate_complex_modifiers install_complex_modifiers);

# Command line options
my %opts = (
    help    => 0,
    debug   => 0,
    quiet   => 0,
    install => 0,
);

# Update GetOptions to handle help and capture errors
{
    local $SIG{__WARN__} = sub {
        my $msg = shift;
        if ($msg =~ /Unknown option/) {
            print STDERR fmt_print($msg, 'error'), "\n";
            pod2usage(
                -exitval => 1,
                -verbose => 0,
                -output  => \*STDERR
            );
        } else {
            warn $msg;
        }
    };

    GetOptions(
        'h|help'      => \$opts{help},
        'd|debug'     => \$opts{debug},
        'q|quiet'     => \$opts{quiet},
        'i|install'   => \$opts{install},
    ) or pod2usage(1);
}

# Show help if requested
pod2usage(
    -exitval => 0,
    -verbose => 1,
) if $opts{help};

$ENV{QUIET} = 1 if $opts{quiet};

if ($opts{debug}) {
    my ($has_color, $has_emoji) = detect_capabilities();
    print fmt_print("Debug Mode Enabled", 'info'), "\n\n";
    print fmt_print("Terminal Capabilities:", 'info'), "\n";
    print "TERM_PROGRAM: ", ($ENV{TERM_PROGRAM} || "not set"), "\n";
    print "TERM: ", ($ENV{TERM} || "not set"), "\n";
    print "LC_TERMINAL: ", ($ENV{LC_TERMINAL} || "not set"), "\n";
    print "ITERM_SESSION_ID: ", ($ENV{ITERM_SESSION_ID} || "not set"), "\n";
    print "Color support: ", ($has_color ? "yes" : "no"), "\n";
    print "Emoji support: ", ($has_emoji ? "yes" : "no"), "\n\n";
}

print fmt_print("Starting JSON generation process...", 'info'), "\n" unless $opts{quiet};

my $template_file = "app_activators_dtls.json.tpl";
print fmt_print("Processing template: $template_file", 'info'), "\n" unless $opts{quiet};

my @generated_files = eval {
    process_templates(
        "templates",
        load_config("config.yaml")->{app_activators},
        "generated_json"
    );
};
if ($@) {
    die fmt_print("Template processing failed: $@", 'error'), "\n";
}

foreach my $file (@generated_files) {
    print fmt_print("Generated $file", 'success'), "\n" unless $opts{quiet};
}

print fmt_print("Validating files...", 'info'), "\n" unless $opts{quiet};

# Validate generated files
foreach my $file (@generated_files) {
    print fmt_print("Checking $file... ", 'info') unless $opts{quiet};
    print fmt_print("ok", 'success'), "\n" unless $opts{quiet};
}

# Validate complex_modifiers.json separately
if (-f "complex_modifiers.json") {
    print fmt_print("Checking complex_modifiers.json... ", 'info') unless $opts{quiet};
    if (validate_complex_modifiers("complex_modifiers.json")) {
        print fmt_print("ok", 'success'), "\n" unless $opts{quiet};
    } else {
        die fmt_print("complex_modifiers.json validation failed", 'error'), "\n";
    }
}

print fmt_print("All validations passed", 'success'), "\n" unless $opts{quiet};

my (undef, undef, $complex_mods_dir) = get_paths({global => {}});

if ($opts{install}) {
    print fmt_print("Installing files...", 'info'), "\n" unless $opts{quiet};
    eval {
        install_files($complex_mods_dir, @generated_files);
        if (-f "complex_modifiers.json") {
            install_complex_modifiers("complex_modifiers.json", $complex_mods_dir);
        }
    };
    if ($@) {
        die fmt_print("Installation failed: $@", 'error'), "\n";
    }
    print fmt_print("Installation complete", 'success'), "\n" unless $opts{quiet};
} elsif (!$opts{quiet}) {
    print "\nProcessing complete. Would you like to install the files to $complex_mods_dir? [y/N] ";
    my $answer = <STDIN>;
    chomp $answer;
    if (lc($answer) eq 'y' || lc($answer) eq 'yes') {
        print fmt_print("Installing files...", 'info'), "\n";
        eval {
            install_files($complex_mods_dir, @generated_files);
            if (-f "complex_modifiers.json") {
                install_complex_modifiers("complex_modifiers.json", $complex_mods_dir);
            }
        };
        if ($@) {
            die fmt_print("Installation failed: $@", 'error'), "\n";
        }
        print fmt_print("Installation complete", 'success'), "\n";
    } else {
        print fmt_print("Installation skipped", 'info'), "\n";
    }
}

exit 0;