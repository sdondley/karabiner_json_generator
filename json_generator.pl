#!/usr/bin/env perl
use strict;
use warnings;
use JSON;
use YAML::XS qw(LoadFile);
use File::Basename;
use Template;

# Read configuration from YAML file
my $config = LoadFile('config.yaml') or die "Cannot read config file: $!";

# Get list of template files
my $template_dir = "templates";
opendir(my $dh, $template_dir) or die "Cannot open template directory: $!";
my @template_files = grep { /\.json$/ } readdir($dh);
closedir($dh);

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

    # Pretty print the JSON
    my $json_obj = decode_json($output);
    my $pretty_json = JSON->new->pretty->encode($json_obj);

    # Write to output file
    my $output_file = "$base_name.json";
    open(my $fh, '>', $output_file) or die "Cannot open output file $output_file: $!";
    print $fh $pretty_json;
    close($fh);
}