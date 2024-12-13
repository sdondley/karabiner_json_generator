#!/usr/bin/env bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to create a directory
create_dir() {
    local dir=$1
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        echo -e "${GREEN}Created directory:${NC} $dir"
    else
        echo -e "${BLUE}Directory already exists:${NC} $dir"
    fi
}

# Function to create a file with content
create_file() {
    local file=$1
    local content=$2
    
    if [ ! -f "$file" ]; then
        echo -e "$content" > "$file"
        echo -e "${GREEN}Created file:${NC} $file"
    else
        echo -e "${BLUE}File already exists:${NC} $file"
    fi
}

# Start setup
echo -e "${BLUE}Setting up Karabiner Generator project structure...${NC}"

# Create directory structure
create_dir "bin"
create_dir "lib/KarabinerGenerator"
create_dir "t"
create_dir "templates"

# Create main script
create_file "bin/json_generator.pl" '#!/usr/bin/env perl
use strict;
use warnings;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";
use Getopt::Std;

use KarabinerGenerator::Config qw(load_config get_paths);
use KarabinerGenerator::Terminal qw(detect_capabilities fmt_print);
use KarabinerGenerator::Template qw(process_templates);
use KarabinerGenerator::Validator qw(validate_files);
use KarabinerGenerator::Installer qw(install_files);

our %opts;
getopts("diq", \%opts);

# Main script logic here
'

# Create Config.pm
create_file "lib/KarabinerGenerator/Config.pm" 'package KarabinerGenerator::Config;
use strict;
use warnings;
use YAML::XS qw(LoadFile);
use File::Spec;
use Exporter "import";

our @EXPORT_OK = qw(load_config get_paths validate_config);

sub load_config {
    my ($config_file) = @_;
    my $config = eval { LoadFile($config_file) } || {};
    my $global_config = eval { LoadFile("global_config.yaml") } || {};
    
    $config->{global} = $global_config;
    return $config;
}

sub get_paths {
    my ($global_config) = @_;
    # Path resolution logic here
    return;
}

1;
'

# Create Terminal.pm
create_file "lib/KarabinerGenerator/Terminal.pm" 'package KarabinerGenerator::Terminal;
use strict;
use warnings;
use Exporter "import";

our @EXPORT_OK = qw(detect_capabilities fmt_print);

sub detect_capabilities {
    # Terminal capability detection logic
    return;
}

sub fmt_print {
    my ($text, $style, $force) = @_;
    # Formatting logic here
    return $text;
}

1;
'

# Create Template.pm
create_file "lib/KarabinerGenerator/Template.pm" 'package KarabinerGenerator::Template;
use strict;
use warnings;
use Template;
use JSON;
use File::Path qw(make_path);
use Exporter "import";

our @EXPORT_OK = qw(process_templates);

sub process_templates {
    my ($template_dir, $config, $output_dir) = @_;
    my @generated_files;
    # Template processing logic here
    return @generated_files;
}

1;
'

# Create Validator.pm
create_file "lib/KarabinerGenerator/Validator.pm" 'package KarabinerGenerator::Validator;
use strict;
use warnings;
use Exporter "import";

our @EXPORT_OK = qw(validate_files);

sub validate_files {
    my ($cli_path, @files) = @_;
    my $all_valid = 1;
    # Validation logic here
    return $all_valid;
}

1;
'

# Create Installer.pm
create_file "lib/KarabinerGenerator/Installer.pm" 'package KarabinerGenerator::Installer;
use strict;
use warnings;
use File::Copy;
use File::Path qw(make_path);
use Exporter "import";

our @EXPORT_OK = qw(install_files);

sub install_files {
    my ($complex_mods_dir, @files) = @_;
    # Installation logic here
    return 1;
}

1;
'

# Create Utils.pm
create_file "lib/KarabinerGenerator/Utils.pm" 'package KarabinerGenerator::Utils;
use strict;
use warnings;
use Exporter "import";

our @EXPORT_OK = qw(expand_path);

sub expand_path {
    my ($path) = @_;
    $path =~ s/^~/$ENV{HOME}/;
    return $path;
}

1;
'

# Create basic test files
create_file "t/01_config.t" '#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use KarabinerGenerator::Config qw(load_config get_paths);

# Test cases here
done_testing;
'

create_file "t/02_terminal.t" '#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use KarabinerGenerator::Terminal qw(detect_capabilities fmt_print);

# Test cases here
done_testing;
'

# Make the main script executable
chmod +x "bin/json_generator.pl"

echo -e "${GREEN}Setup complete!${NC}"
echo -e "${BLUE}Next steps:${NC}"
echo "1. Review and customize the module files"
echo "2. Implement the core functionality in each module"
echo "3. Write tests in the t/ directory"
echo "4. Run tests using 'prove -l t/*.t'"