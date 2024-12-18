#!/usr/bin/env perl
# json_generator.pl - Generate Karabiner-Elements JSON configuration files

=head1 NAME

json_generator.pl - Generate Karabiner-Elements JSON configuration files

=head1 SYNOPSIS

json_generator.pl [options]

 Options:
   -h, --help     Show this help message
   -d, --debug    Enable debug output
   -i, --install  Automatically install after generation
   -e, --enable   Enable generated rules in karabiner.json (requires -i)
   -p, --profiles Use profile-based configuration (requires -i)
   -q, --quiet    Minimize output messages

=head1 DESCRIPTION

This script generates JSON configuration files for Karabiner-Elements from YAML templates.
It can validate the generated files and optionally install them into your Karabiner-Elements
configuration directory. With the -e option, it can also enable the generated rules in your
karabiner.json configuration file.

The -e and -p options are mutually exclusive:
  -e creates a single "Generated Json" profile with all rules
  -p uses profile configuration from profile_config.yaml to create multiple profiles

=cut

use strict;
use warnings;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";
use Getopt::Long qw(:config bundling no_ignore_case);
use Pod::Usage;
use File::Basename;
use File::Spec;

use KarabinerGenerator::Config qw(load_config get_path);
use KarabinerGenerator::Terminal qw(detect_capabilities fmt_print);
use KarabinerGenerator::Template qw(process_templates);
use KarabinerGenerator::Validator qw(validate_files);
use KarabinerGenerator::Installer qw(install_files);
use KarabinerGenerator::ComplexModifiers qw(validate_complex_modifiers install_complex_modifiers);
use KarabinerGenerator::CLI qw(run_ke_cli_cmd);
use KarabinerGenerator::KarabinerJsonFile qw(
    read_karabiner_json
    write_karabiner_json
    update_generated_rules
);
use KarabinerGenerator::Profiles qw(
    has_profile_config
    generate_config
    validate_profile_config
    bundle_profile
    get_profile_names
    install_bundled_profile
);

# Command line options
my %opts = (
    help     => 0,
    debug    => 0,
    quiet    => 0,
    install  => 0,
    enable   => 0,
    profiles => 0,
);

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
        'e|enable'    => \$opts{enable},
        'p|profiles'  => \$opts{profiles},
    ) or pod2usage(1);
}

# Show help if requested
if ($opts{help}) {
    pod2usage({
        -exitval => 0,
        -verbose => 1,
        -output  => \*STDOUT,
        -sections => [qw(NAME SYNOPSIS DESCRIPTION)],
    });
}

# Maintain original error check for -e requiring -i
if ($opts{enable} && !$opts{install}) {
    print STDERR "-e/--enable option requires -i/--install\n";
    exit 1;
}

# Then check for -e and -p conflict
if ($opts{enable} && $opts{profiles}) {
    print STDERR fmt_print("Cannot use -e/--enable with -p/--profiles\n", 'error');
    exit 1;
}

# Finally check -p requiring -i
if ($opts{profiles} && !$opts{install}) {
    print STDERR fmt_print("-p/--profiles option requires -i/--install\n", 'error');
    exit 1;
}

$ENV{QUIET} = 1 if $opts{quiet};

my $config = load_config();
my $complex_mods_dir = get_path('complex_mods_dir');
my $complex_mods_json = get_path('complex_modifiers_json');

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

print fmt_print("Starting JSON generation process...", 'info'), "\n\n" unless $opts{quiet};
print fmt_print("Generating JSON files from templates...", 'info'), "\n" unless $opts{quiet};

# Generate JSON files
my @generated_files;
{
    local $@;
    @generated_files = eval {
        process_templates(
            get_path('templates_dir'),
            $config->{app_activators},
            get_path('generated_json_dir')
        );
    };
    if ($@) {
        my $error = $@;
        if ($error =~ /Template error:/) {
            die fmt_print("Template syntax error: $error", 'error'), "\n";
        }
        elsif ($error =~ /Cannot (?:read|write|open) file/) {
            die fmt_print("File operation failed: $error", 'error'), "\n";
        }
        die fmt_print("Template processing failed: $error", 'error'), "\n";
    }
}

print "\n" unless $opts{quiet};
print fmt_print("Validating JSON files...", 'info'), "\n" unless $opts{quiet};

# Validate generated files
unless (validate_files(@generated_files)) {
    die fmt_print("File validation failed", 'error'), "\n";
}

# Validate complex_modifiers.json if it exists
if (-f $complex_mods_json) {
    if (!validate_complex_modifiers($complex_mods_json)) {
        die fmt_print("complex_modifiers.json validation failed", 'error'), "\n";
    }
}

# Handle installation
my $should_install = $opts{install};
if (!$should_install && !$opts{quiet} && !$ENV{TEST_MODE}) {
    print "\nWould you like to install the files to $complex_mods_dir? [y/N] ";
    my $answer = <STDIN>;
    chomp $answer;
    $should_install = lc($answer) eq 'y' || lc($answer) eq 'yes';
}

if ($should_install) {
    print fmt_print("Installing files...", 'info'), "\n" unless $opts{quiet};
    eval {
        install_files($complex_mods_dir, @generated_files);
        if (-f $complex_mods_json) {
            install_complex_modifiers($complex_mods_json, $complex_mods_dir);
        }

        if ($opts{profiles}) {
            # Profile-based workflow
            unless (has_profile_config()) {
                print fmt_print("No profile configuration found. Generating default config...", 'info'), "\n"
                    unless $opts{quiet};
                generate_config();
            }

            my $validation = validate_profile_config();
            unless ($validation->{valid}) {
                die "Invalid profile configuration:\n" .
                    join("\n", map { "  - $_" } @{$validation->{missing_files}});
            }

            # Get and process all profiles
            my @profiles = get_profile_names();
            foreach my $profile_name (@profiles) {
                print fmt_print("Processing profile: $profile_name", 'info'), "\n" unless $opts{quiet};

                # Bundle the profile
                bundle_profile($profile_name) or die "Failed to bundle profile: $profile_name";

                # Install the bundled profile
                install_bundled_profile($profile_name) or die "Failed to install profile: $profile_name";
            }

            print fmt_print("Profiles installed successfully", 'success'), "\n" unless $opts{quiet};
        }
        elsif ($opts{enable}) {
            print fmt_print("Enabling generated rules...", 'info'), "\n" unless $opts{quiet};
            my $karabiner_json = get_path('karabiner_json');
            my $karabiner_config = read_karabiner_json($karabiner_json);

            unless (update_generated_rules($karabiner_config, $complex_mods_dir)) {
                die "Failed to update generated rules";
            }
            unless (write_karabiner_json($karabiner_config, $karabiner_json)) {
                die "Failed to write karabiner.json";
            }
            print fmt_print("Rules enabled successfully", 'success'), "\n" unless $opts{quiet};
        }
    };
    if ($@) {
        die fmt_print("Installation failed: $@", 'error'), "\n";
    }
    print fmt_print("Installation complete", 'success'), "\n" unless $opts{quiet};
} else {
    print fmt_print("Installation skipped", 'info'), "\n" unless $opts{quiet};
}

if ($ENV{TEST_MODE}) {
    print fmt_print("Test Mode: Using directory " . get_path('templates_dir'), 'info'), "\n"
        unless $opts{quiet};
}

exit 0;