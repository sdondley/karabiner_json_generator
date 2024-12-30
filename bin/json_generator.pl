#!/usr/bin/env perl
# json_generator.pl - Generate Karabiner-Elements JSON configuration files
package KarabinerGenerator::Generator;

use strict;
use warnings;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";
use Getopt::Long qw(:config bundling no_ignore_case);
use Pod::Usage;
use File::Spec;
use KarabinerGenerator::Installer qw(install_files);
use KarabinerGenerator::Config qw(get_path load_config);
use KarabinerGenerator::Init qw(init db dbd is_test_mode);
use KarabinerGenerator::Template qw(process_templates);
use KarabinerGenerator::Terminal qw(fmt_print);
use KarabinerGenerator::JSONHandler qw(read_json_file write_json_file);
#use KarabinerGenerator::KarabinerInstallation qw(reset_karabiner_installation);
use KarabinerGenerator::Profiles qw(
    has_profile_config
    install_profile
    validate_profile_config
    PROFILE_PREFIX
);

sub run {
    my ($class, %opts) = @_;
    db("\n### ENTERING json_generator.pl ###");
    db("RealBin: $RealBin");

    # Use passed options or parse from command line
    unless (%opts) {
        local $SIG{__WARN__} = sub {
            my $msg = shift;
            if ($msg =~ /Unknown option/) {
                db("Got unknown option warning: $msg");
                print STDERR $msg;
                pod2usage(1);
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
            'r|reset'     => \$opts{reset},
        ) or pod2usage(1);
    }

    db("Options:");
    for my $key (sort keys %opts) {
        db("  $key: " . ($opts{$key} ? "YES" : "NO"));
    }

    db("RealBin when help called: $RealBin");
    db("Called as: " . (caller() ? "module" : "script"));

    if ($opts{help}) {
        my $pod_content;
        open my $str_fh, '>', \$pod_content;
        my $input = caller() ? __PACKAGE__ : "$RealBin/json_generator.pl";
        db("RealBin when help called: $RealBin");
        db("Called as: " . (caller() ? "module" : "script"));
        db("Using POD input path: $input");
        pod2usage(
            -exitval => 'NOEXIT',
            -output => $str_fh,
            -input => __FILE__,  # Just use current file
            -verbose => 1
        );
        close $str_fh;
        print $pod_content;
        return $pod_content;
    }

    # Validate options
    if ($opts{enable} && !$opts{install}) {
        die "-e/--enable option requires -i/--install\n";
    }
    if ($opts{profiles} && !$opts{install}) {
        die "-p/--profiles option requires -i/--install\n";
    }
    if ($opts{enable} && $opts{profiles}) {
        die "Cannot use -e/--enable with -p/--profiles\n";
    }

    $ENV{QUIET} = 1 if $opts{quiet};
    $ENV{DEBUG} = 1 if $opts{debug};

    init() unless is_test_mode;

    # Handle reset option
    if ($opts{reset}) {
        # Check for conflicting options
        my @other_opts = grep { $_ ne 'reset' && $_ ne 'quiet' && $_ ne 'debug' }
                        grep { $opts{$_} }
                        keys %opts;

        if (@other_opts) {
            die "--reset cannot be used with other options\n";
        }

        print fmt_print("Resetting Karabiner configuration...", 'info'), "\n" unless $opts{quiet};
        reset_karabiner_installation();
        print fmt_print("Reset complete", 'success'), "\n" unless $opts{quiet};
        return [];
    }

    # Load configuration and process templates
    my $config = load_config();
    print fmt_print("Starting JSON generation process...", 'info'), "\n\n" unless $opts{quiet};
    print fmt_print("Generating JSON files from templates...", 'info'), "\n" unless $opts{quiet};

    my @generated_files = eval {
        process_templates($config);
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

    print fmt_print("JSON generation complete", 'success'), "\n" unless $opts{quiet};

    # Handle installation
    if ($opts{install}) {
        my $complex_mods_dir = get_path('karabiner_complex_mods_dir');
        print fmt_print("Installing files...", 'info'), "\n" unless $opts{quiet};

        # Install generated files
        install_files($complex_mods_dir, @generated_files)
            or die fmt_print("Failed to install generated files", 'error'), "\n";

        if ($opts{profiles}) {
            # Check for profile configuration
            unless (has_profile_config()) {
                print fmt_print("No profile configuration found.", 'error'), "\n" unless $opts{quiet};
                die "Profile configuration is required when using --profiles\n";
            }

            # Validate profile configuration
            my $validation = validate_profile_config();
            unless ($validation->{valid}) {
                die "Invalid profile configuration:\n" .
                    join("\n", map { "  - $_" } @{$validation->{missing_files}});
            }

            # Process each profile
            my $profile_config = $config->{profiles};
            for my $profile_name (sort keys %{$profile_config->{profiles}}) {
                print fmt_print("Processing profile: $profile_name", 'info'), "\n" unless $opts{quiet};

                # Install profile to karabiner.json
                unless (install_profile($profile_name)) {
                    die fmt_print("Failed to install profile: $profile_name", 'error'), "\n";
                }
            }

            print fmt_print("Profiles installed successfully", 'success'), "\n" unless $opts{quiet};
        }
        elsif ($opts{enable}) {
            print fmt_print("Enabling generated rules...", 'info'), "\n" unless $opts{quiet};

            my $karabiner_json = get_path('karabiner_json');
            my $config = eval { read_json_file($karabiner_json) };
            die fmt_print("Failed to read karabiner.json: $@", 'error'), "\n" if $@;

            # Find or create Generated JSON profile
            my ($profile) = grep { $_->{name} eq 'Generated JSON' } @{$config->{profiles}};
            unless ($profile) {
                push @{$config->{profiles}}, {
                    name => 'Generated JSON',
                    complex_modifications => { rules => [] },
                    parameters => {},
                    selected => JSON::false,
                    simple_modifications => [],
                    fn_function_keys => [],
                    devices => []
                };
                $profile = $config->{profiles}[-1];
            }

            # Clear existing rules
            $profile->{complex_modifications}{rules} = [];

            # Add new rules from generated files
            for my $file (@generated_files) {
                my $rule_data = eval { read_json_file($file) };
                if ($@) {
                    die fmt_print("Failed to read rule file $file: $@", 'error'), "\n";
                }
                push @{$profile->{complex_modifications}{rules}}, @{$rule_data->{rules}};
            }

            # Save changes
            eval { write_json_file($karabiner_json, $config) };
            die fmt_print("Failed to write karabiner.json: $@", 'error'), "\n" if $@;

            print fmt_print("Rules enabled successfully", 'success'), "\n" unless $opts{quiet};
        }

        print fmt_print("Installation complete", 'success'), "\n" unless $opts{quiet};
    }

    print fmt_print("Processing complete", 'success'), "\n" unless $opts{quiet};
    return \@generated_files;
}

# Run as script if invoked directly
run(__PACKAGE__) unless caller();

1;

__END__

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
   -r, --reset    Reset Karabiner configuration to defaults (cannot be used with other options)

=head1 DESCRIPTION

This script generates JSON configuration files for Karabiner-Elements from YAML templates.
It can also reset your Karabiner configuration back to a clean state using the reset option.