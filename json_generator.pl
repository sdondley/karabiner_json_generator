#!/usr/bin/env perl

use strict;
use warnings;
use JSON;
use YAML::XS qw(LoadFile);
use File::Basename;
use Template;
use Getopt::Std;
use File::Copy;
use File::Spec;
use File::Path qw(make_path);

# Get command line options
our %opts;
getopts('diq', \%opts);  # Added 'q' option for quiet mode

# Create generated_json directory if it doesn't exist
my $generated_dir = "generated_json";
make_path($generated_dir) unless -d $generated_dir;

# Check terminal capabilities
my $has_color = 0;
my $has_emoji = 0;

# Check for color support
eval {
    require Term::ANSIColor;
    Term::ANSIColor->import();
    $has_color = 1;
};

# Check for iTerm2 in various ways
$has_emoji = 1 if $ENV{TERM_PROGRAM} && $ENV{TERM_PROGRAM} eq 'iTerm.app';
$has_emoji = 1 if $ENV{LC_TERMINAL} && $ENV{LC_TERMINAL} eq 'iTerm2';
$has_emoji = 1 if $ENV{ITERM_SESSION_ID};

if ($opts{d}) {
    print "Terminal debug info:\n";
    print "TERM_PROGRAM: ", ($ENV{TERM_PROGRAM} || "not set"), "\n";
    print "TERM: ", ($ENV{TERM} || "not set"), "\n";
    print "LC_TERMINAL: ", ($ENV{LC_TERMINAL} || "not set"), "\n";
    print "ITERM_SESSION_ID: ", ($ENV{ITERM_SESSION_ID} || "not set"), "\n";
    print "Color support: ", ($has_color ? "yes" : "no"), "\n";
    print "Emoji support: ", ($has_emoji ? "yes" : "no"), "\n\n";
}

# Helper function for formatted output
sub fmt_print {
    my ($text, $style, $force) = @_;

    # Return empty string if in quiet mode and not forced
    return "" if $opts{q} && !$force && $style ne 'error';

    if ($style eq 'error' && $has_emoji) {
        return "❌ $text";
    } elsif ($style eq 'success' && $has_emoji) {
        return "✅  $text";
    } elsif ($style eq 'warn' && $has_emoji) {
        return "⚠️  $text";
    } elsif ($style eq 'info' && $has_emoji) {
        return "ℹ️  $text";
    } elsif ($style eq 'bullet' && $has_emoji) {
        return "• $text";
    } else {
        # Fallback formatting without emoji
        my $prefix = $style eq 'error' ? 'ERROR: ' :
                    $style eq 'success' ? 'SUCCESS: ' :
                    $style eq 'warn' ? 'WARNING: ' :
                    $style eq 'info' ? 'INFO: ' :
                    $style eq 'bullet' ? '* ' : '';
        return "$prefix$text";
    }
}

# Default paths
my $default_cli_path = '/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli';
my $default_config_dir = File::Spec->catfile($ENV{HOME}, '.config', 'karabiner');
my $default_complex_mods_dir = File::Spec->catfile($default_config_dir, 'assets', 'complex_modifications');

# Read global configuration
my $global_config = eval { LoadFile('global_config.yaml') } || {};

# Set paths with fallbacks to defaults
my $cli_path = expand_path($global_config->{karabiner}{cli_path} || $default_cli_path);
my $config_dir = expand_path($global_config->{karabiner}{config_dir} || $default_config_dir);
my $complex_mods_dir = expand_path($global_config->{karabiner}{complex_mods_dir} || $default_complex_mods_dir);

# Read configuration from YAML file
my $config = LoadFile('config.yaml') or die fmt_print("Cannot read config file: $!", 'error');

# Merge global config into local config
$config->{global} = $global_config;

# Get list of template files
my $template_dir = "templates";
opendir(my $dh, $template_dir) or die fmt_print("Cannot open template directory: $!", 'error');
my @template_files = grep { /\.json\.tpl$/ } readdir($dh);  # Changed to look for .json.tpl files
closedir($dh);

# Track generated files for validation
my @generated_files;

print fmt_print("Starting JSON generation process...", 'info'), "\n" unless $opts{q};

foreach my $template_file (@template_files) {
    # Get base filename without extension (remove both .tpl and .json)
    my ($base_name, undef, undef) = fileparse($template_file, qr/\.json\.tpl$/);  # Updated pattern

    # Skip if no matching config exists
    next unless exists $config->{$base_name};

    print fmt_print("Processing template: $template_file", 'info'), "\n" unless $opts{q};

    # Read template file
    open(my $tfh, '<', "$template_dir/$template_file") or die fmt_print("Cannot open template $template_file: $!", 'error');
    local $/;  # Enable slurp mode
    my $template_content = <$tfh>;
    close($tfh);

    # Create Template Toolkit object
    my $tt = Template->new();

    # Process template with config data
    my $output;
    $tt->process(\$template_content, $config->{$base_name}, \$output)
        or die fmt_print($tt->error(), 'error');

    # Debug output if -d flag is provided
    if ($opts{d}) {
        print "=== Raw template output ===\n";
        print $output;
        print "\n=== End raw output ===\n";
    }

    # Try parsing JSON and format with specific spacing
    eval {
        my $json_obj = decode_json($output);

        # Create JSON encoder with specific formatting
        my $json = JSON->new->indent(1)->space_after(0)->space_before(0);

        # Write to output file in generated_json directory with .json extension
        my $output_file = File::Spec->catfile($generated_dir, "$base_name.json");  # Ensures .json extension
        open(my $fh, '>', $output_file) or die fmt_print("Cannot open output file $output_file: $!", 'error');
        print $fh $json->encode($json_obj);
        close($fh);

        push @generated_files, $output_file;
        print fmt_print("Generated $output_file", 'success'), "\n" unless $opts{q};
    };
    if ($@) {
        my $error = "JSON parsing error: $@";
        print fmt_print($error, 'error', 1), "\n";

        if ($opts{d} && $@ =~ /at character offset (\d+)/) {
            my $offset = $1;
            print "Context around error (offset $offset):\n";
            print "..." . substr($output, max(0, $offset - 50), 100) . "...\n";
            print " " x (53) . "^\n";
        }
        exit 1;
    }
}

# Track core configuration file
my $complex_modifiers_file = File::Spec->catfile(dirname($0), 'complex_modifiers.json');
my $has_complex_modifiers = -f $complex_modifiers_file;

# Validate and install generated files if karabiner_cli is available
if (-x $cli_path) {
    print fmt_print("Validating generated files...", 'info'), "\n" unless $opts{q};
    my $all_valid = 1;

    # Validate generated files
    foreach my $file (@generated_files) {
        print fmt_print("Checking $file...", 'info'), " " unless $opts{q};
        my $result;
        if ($opts{q}) {
            $result = system("'$cli_path' --lint-complex-modifications $file >/dev/null 2>&1");
        } else {
            $result = system($cli_path, '--lint-complex-modifications', $file);
        }
        if ($result == 0) {
            print fmt_print("OK", 'success'), "\n" unless $opts{q};
        } else {
            print fmt_print("FAILED", 'error', 1), "\n";
            $all_valid = 0;
        }
    }

    # Also validate complex_modifiers.json if present
    if ($has_complex_modifiers) {
        print fmt_print("Checking complex_modifiers.json...", 'info'), " " unless $opts{q};
        my $result;
        if ($opts{q}) {
            $result = system("'$cli_path' --lint-complex-modifications $complex_modifiers_file >/dev/null 2>&1");
        } else {
            $result = system($cli_path, '--lint-complex-modifications', $complex_modifiers_file);
        }
        if ($result == 0) {
            print fmt_print("OK", 'success'), "\n" unless $opts{q};
        } else {
            print fmt_print("FAILED", 'error', 1), "\n";
            $all_valid = 0;
        }
    }

    if ($all_valid) {
        my $should_install = 0;
        if ($opts{i}) {
            $should_install = 1;
            print fmt_print("Auto-installing files due to -i flag...", 'info'), "\n" unless $opts{q};
        } elsif (!$opts{q}) {
            print fmt_print("All files passed validation.", 'success'), "\n";
            print "\nProcesssing complete. Would you like to install the files to $complex_mods_dir? [y/N] ";
            my $answer = <STDIN>;
            chomp $answer;
            $should_install = lc($answer) eq 'y' || lc($answer) eq 'yes';
        }
        # Modify the installation section to copy from generated_json directory
        if ($should_install) {
            print fmt_print("Installing to $complex_mods_dir...", 'info'), "\n" unless $opts{q};

            # Create directory if it doesn't exist
            make_path($complex_mods_dir);

            # Copy generated files from generated_json directory
            foreach my $file (@generated_files) {
                my $base = basename($file);
                my $dest = File::Spec->catfile($complex_mods_dir, $base);
                copy($file, $dest) or die fmt_print("Failed to copy $file to $dest: $!", 'error');
                print fmt_print("Installed $base", 'success'), "\n" unless $opts{q};
            }

            # Copy complex_modifiers.json if present
            if ($has_complex_modifiers) {
                my $dest = File::Spec->catfile($complex_mods_dir, 'complex_modifiers.json');
                copy($complex_modifiers_file, $dest) or die fmt_print("Failed to copy complex_modifiers.json to $dest: $!", 'error');
                print fmt_print("Installed complex_modifiers.json", 'success'), "\n" unless $opts{q};
            } else {
                print fmt_print("Warning: complex_modifiers.json not found in script directory", 'warn', 1), "\n";
            }

            print fmt_print("Installation complete", 'success'), "\n" unless $opts{q};
        } else {
            print fmt_print("Installation skipped", 'info'), "\n" unless $opts{q};
        }
    } else {
        print fmt_print("Some files failed validation. Not installing.", 'error', 1), "\n";
        exit 1;
    }
} else {
    print fmt_print("Warning: karabiner_cli not found at $cli_path. Skipping validation and installation.", 'warn', 1), "\n";
}

sub max {
    my ($a, $b) = @_;
    return $a > $b ? $a : $b;
}

sub expand_path {
    my ($path) = @_;
    $path =~ s/^~/$ENV{HOME}/;
    return $path;
}

# Check for required modules before loading them
BEGIN {
    my %required_modules = (
        'JSON' => 'JSON',
        'YAML::XS' => 'YAML-LibYAML',
        'Template' => 'Template-Toolkit'
    );

    my @missing_modules;
    foreach my $module (keys %required_modules) {
        eval "require $module";
        if ($@) {
            push @missing_modules, [$module, $required_modules{$module}];
        }
    }

    if (@missing_modules) {
        print "\nERROR: Missing required Perl modules:\n\n";
        foreach my $module (@missing_modules) {
            print "   * $module->[0]\n";
        }
        print "\nHere are your options to install the missing modules, from most recommended to least:\n\n";

        # Option 1: Homebrew
        print "OPTION 1: Using Homebrew (RECOMMENDED for most users)\n";
        print "============================================\n";
        print "This is the simplest method for Mac users who just want to get things working quickly.\n\n";
        print "1. First install Homebrew if you haven't already:\n";
        print "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"\n\n";
        print "2. Then install the Perl modules:\n";
        foreach my $module (@missing_modules) {
            print "   brew install perl-$module->[1]\n";
        }
        print "\n";

        # Option 2: Perlbrew
        print "OPTION 2: Using Perlbrew (RECOMMENDED for Perl developers)\n";
        print "================================================\n";
        print "This is the best option if you plan to do more Perl development. It keeps your\n";
        print "system Perl clean and gives you more control over your Perl environment.\n\n";
        print "1. Install Perlbrew:\n";
        print "   curl -L https://install.perlbrew.pl | bash\n\n";
        print "2. Add Perlbrew to your shell (you'll need to restart your terminal after this):\n";
        print "   echo 'source ~/perl5/perlbrew/etc/bashrc' >> ~/.zshrc\n\n";
        print "3. Install a fresh version of Perl:\n";
        print "   perlbrew install perl-5.36.0\n";
        print "   perlbrew switch perl-5.36.0\n\n";
        print "4. Install cpanm:\n";
        print "   perlbrew install-cpanm\n\n";
        print "5. Install the required modules:\n";
        foreach my $module (@missing_modules) {
            print "   cpanm $module->[0]\n";
        }
        print "\n";

        # Option 3: System Perl
        print "OPTION 3: Using System Perl (NOT RECOMMENDED)\n";
        print "======================================\n";
        print "This method works but isn't recommended as it modifies your system Perl installation.\n";
        print "Only use this if you're sure you know what you're doing.\n\n";
        print "1. Install the cpanm tool:\n";
        print "   sudo cpan App::cpanminus\n\n";
        print "2. Install the missing modules:\n";
        foreach my $module (@missing_modules) {
            print "   sudo cpanm $module->[0]\n";
        }
        print "\n";

        # Final notes
        print "NOTES:\n";
        print "- After installing using any method, you'll need to run this script again\n";
        print "- If you're not sure which option to choose, go with Option 1 (Homebrew)\n";
        print "- If you run into any issues, feel free to open an issue on the GitHub repository\n\n";

        exit 1;
    }
}