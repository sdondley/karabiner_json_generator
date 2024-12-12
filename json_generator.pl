#!/usr/bin/env perl

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
        print "\n❌ Error: Some required Perl modules are missing.\n\n";
        foreach my $module (@missing_modules) {
            print "   - $module->[0]\n";
        }
        print "\nThere are several ways to install the missing modules. Here are your options, from most recommended to least:\n\n";

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
getopts('di', \%opts);  # Added 'i' option for automatic installation

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
my $config = LoadFile('config.yaml') or die "Cannot read config file: $!";

# Merge global config into local config
$config->{global} = $global_config;

# Get list of template files
my $template_dir = "templates";
opendir(my $dh, $template_dir) or die "Cannot open template directory: $!";
my @template_files = grep { /\.json$/ } readdir($dh);
closedir($dh);

# Track generated files for validation
my @generated_files;

foreach my $template_file (@template_files) {
    # Get base filename without extension
    my ($base_name, undef, undef) = fileparse($template_file, qr/\.[^.]*/);

    # Skip if no matching config exists
    next unless exists $config->{$base_name};

    # Read template file
    open(my $tfh, '<', "$template_dir/$template_file") or die "Cannot open template $template_file: $!";
    local $/;  # Enable slurp mode
    my $template_content = <$tfh>;
    close($tfh);

    # Create Template Toolkit object
    my $tt = Template->new();

    # Process template with config data
    my $output;
    $tt->process(\$template_content, $config->{$base_name}, \$output)
        or die $tt->error();

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

        # Write to output file
        my $output_file = "$base_name.json";
        open(my $fh, '>', $output_file) or die "Cannot open output file $output_file: $!";
        print $fh $json->encode($json_obj);
        close($fh);

        push @generated_files, $output_file;
    };
    if ($@) {
        my $error = "JSON parsing error: $@";
        print $error;

        if ($opts{d} && $@ =~ /at character offset (\d+)/) {
            my $offset = $1;
            print "Context around error (offset $offset):\n";
            print "..." . substr($output, max(0, $offset - 50), 100) . "...\n";
            print " " x (53) . "^\n";
        }
        exit 1;
    }
}

# Validate and install generated files if karabiner_cli is available
if (-x $cli_path) {
    print "Validating generated files...\n";

    my $all_valid = 1;
    foreach my $file (@generated_files) {
        print "Checking $file... ";
        my $result = system($cli_path, '--lint-complex-modifications', $file);
        if ($result == 0) {
            print "OK\n";
        } else {
            print "FAILED\n";
            $all_valid = 0;
        }
    }

    if ($all_valid) {
        my $should_install = 0;

        if ($opts{i}) {
            # Automatic installation due to -i flag
            $should_install = 1;
            print "Auto-installing files due to -i flag...\n";
        } else {
            # Ask user for confirmation
            print "\nAll files passed validation.\n";
            print "Would you like to install the files to $complex_mods_dir? [y/N] ";
            my $answer = <STDIN>;
            chomp $answer;
            $should_install = lc($answer) eq 'y' || lc($answer) eq 'yes';
        }

        if ($should_install) {
            print "Installing to $complex_mods_dir...\n";

            # Create directory if it doesn't exist
            make_path($complex_mods_dir);

            # Copy files
            foreach my $file (@generated_files) {
                my $dest = File::Spec->catfile($complex_mods_dir, $file);
                copy($file, $dest) or die "Failed to copy $file to $dest: $!";
                print "Installed $file\n";
            }
            print "Installation complete.\n";
        } else {
            print "Installation skipped.\n";
        }
    } else {
        print "Some files failed validation. Not installing.\n";
        exit 1;
    }
} else {
    print "Warning: karabiner_cli not found at $cli_path. Skipping validation and installation.\n";
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