#!/usr/bin/env perl
# generate_manifest.pl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use YAML::XS;
use File::Find;
use File::Spec;
use File::Basename;

# Get project root directly (don't depend on Config.pm)
my $script_dir = $FindBin::Bin;
my $project_root = dirname(dirname($script_dir));
my $lib_dir = File::Spec->catdir($project_root, 'lib');
my $manifest_file = File::Spec->catfile($project_root, 'newt', 'ManifestTest', 'Manifest.yaml');

print "Project root: $project_root\n";
print "Lib dir: $lib_dir\n";
print "Manifest file: $manifest_file\n";

# Find all .pm files
my @pm_files;
find(sub {
    return unless -f && /\.pm$/;
    push @pm_files, $File::Find::name;
}, $lib_dir);

print "\nFound PM files:\n", join("\n", @pm_files), "\n\n";

# Extract module names and subs without loading modules
my %modules;
for my $file (@pm_files) {
    # Read file content
    open my $fh, '<', $file or die "Cannot open $file: $!";
    my $content = do { local $/; <$fh> };
    close $fh;

    # Get the relative path from lib directory
    my $rel_path = File::Spec->abs2rel($file, $lib_dir);

    # Split path into components and remove .pm
    my @parts = split(/\//, $rel_path);
    $parts[-1] =~ s/\.pm$//;

    # Join with :: to create module name
    my $module = join('::', @parts);

    print "Processing module: $module\n";

    # Extract sub names using regex
    my @subs;
    while ($content =~ /^\s*sub\s+(\w+)\s*\{/mg) {
        push @subs, $1;
    }

    $modules{$module} = [sort @subs];
    print "Found subs: ", join(", ", @subs), "\n\n";
}

# Save manifest
YAML::XS::DumpFile($manifest_file, \%modules);
print "Manifest generated at: $manifest_file\n";