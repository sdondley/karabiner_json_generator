package KarabinerGenerator::ComplexModifiers;
use strict;
use warnings;
use JSON;
use File::Copy;
use File::Path qw(make_path);
use File::Basename qw(basename);
use File::Spec;
use Exporter "import";

our @EXPORT_OK = qw(validate_complex_modifiers install_complex_modifiers);

sub validate_complex_modifiers {
    my ($file) = @_;

    return 0 unless -f $file;

    my $json;
    {
        local $SIG{__WARN__} = sub {}; # Suppress JSON parsing warnings
        eval {
            open my $fh, '<', $file or die "Cannot open $file: $!";
            local $/;
            my $content = <$fh>;
            close $fh;

            $json = JSON->new->decode($content);
        };
        return 0 if $@;
    }

    # Validate required structure
    return 0 unless $json->{title};
    return 0 unless $json->{rules} && ref($json->{rules}) eq 'ARRAY';

    # Validate each rule
    for my $rule (@{$json->{rules}}) {
        return 0 unless $rule->{description};
        return 0 unless $rule->{manipulators} && ref($rule->{manipulators}) eq 'ARRAY';
    }

    return 1;
}

sub install_complex_modifiers {
    my ($source_file, $dest_dir) = @_;

    return 0 unless -f $source_file;

    # Create destination directory if it doesn't exist
    {
        local $SIG{__WARN__} = sub {}; # Suppress directory creation warnings
        eval {
            make_path($dest_dir) unless -d $dest_dir;
        };
        return 0 if $@;
    }

    my $dest_file = File::Spec->catfile($dest_dir, basename($source_file));

    # Copy the file
    if (!copy($source_file, $dest_file)) {
        return 0;
    }

    # Set permissions to match original
    eval {
        my $mode = (stat($source_file))[2] & 07777;
        chmod($mode, $dest_file);
    };

    return 1;
}

1;