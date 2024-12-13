package KarabinerGenerator::Config;
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

sub expand_path {
    my ($path) = @_;
    return unless defined $path;
    $path =~ s/^~/$ENV{HOME}/;
    return $path;
}

sub get_paths {
    my ($global_config) = @_;

    # Default paths
    my $default_cli_path = '/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli';
    my $default_config_dir = File::Spec->catfile($ENV{HOME}, '.config', 'karabiner');
    my $default_complex_mods_dir = File::Spec->catfile($default_config_dir, 'assets', 'complex_modifications');

    # Get configured paths with fallbacks to defaults
    my $cli_path = expand_path($global_config->{karabiner}{cli_path} || $default_cli_path);
    my $config_dir = expand_path($global_config->{karabiner}{config_dir} || $default_config_dir);
    my $complex_mods_dir = expand_path($global_config->{karabiner}{complex_mods_dir} ||
                                     File::Spec->catfile($config_dir, 'assets', 'complex_modifications'));

    return ($cli_path, $config_dir, $complex_mods_dir);
}

1;