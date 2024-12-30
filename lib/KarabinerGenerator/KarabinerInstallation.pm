# KarabinerInstallation.pm
package KarabinerGenerator::KarabinerInstallation;

use strict;
use warnings;
use Exporter 'import';
use File::Spec;
use Carp qw(croak);

our @EXPORT_OK = qw(find_karabiner_installation);

# Default locations
sub _default_config_dir {
    return File::Spec->catdir($ENV{HOME}, '.config', 'karabiner');
}

sub _default_cli_path {
    return '/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli';
}

# Find Karabiner installation directory
sub find_karabiner_installation {
    my %opts = @_;
    my $required = exists $opts{required} ? $opts{required} : 1;

    # Check config directory
    my $config_dir = _default_config_dir();
    my $config_file = File::Spec->catfile($config_dir, 'karabiner.json');
    my $cli_path = _default_cli_path();

    # Basic validation
    if (-d $config_dir && -f $config_file && -r $config_file && -f $cli_path && -x $cli_path) {
        return {
            config_dir => $config_dir,
            cli_path => $cli_path
        };
    }

    # If we get here and it's required, error out
    if ($required) {
        croak "Could not find valid Karabiner installation in ~/.config/karabiner";
    }

    return;
}

1;