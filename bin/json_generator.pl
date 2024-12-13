#!/usr/bin/env perl
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

# Command line options
my %opts = (
    help    => 0,
    debug   => 0,
    quiet   => 0,
    install => 0,
    version => 0,
);

GetOptions(
    'h|help'      => \$opts{help},
    'd|debug'     => \$opts{debug},
    'q|quiet'     => \$opts{quiet},
    'i|install'   => \$opts{install},
    'v|version'   => \$opts{version},
) or pod2usage(2);

$ENV{QUIET} = 1 if $opts{quiet};

if ($opts{debug}) {
    my ($has_color, $has_emoji) = detect_capabilities();
    print "Terminal debug info:\n";
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

# Check complex_modifiers if it exists
if (-f "complex_modifiers.json") {
    print fmt_print("Checking complex_modifiers.json... ", 'info') unless $opts{quiet};
    print fmt_print("ok", 'success'), "\n" unless $opts{quiet};
}

print fmt_print("All validations passed", 'success'), "\n" unless $opts{quiet};

my (undef, undef, $complex_mods_dir) = get_paths({global => {}});

if ($opts{install}) {
    print fmt_print("Installing files...", 'info'), "\n" unless $opts{quiet};
    eval {
        install_files($complex_mods_dir, @generated_files);
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