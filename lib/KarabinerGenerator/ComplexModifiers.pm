package KarabinerGenerator::ComplexModifiers;
use strict;
use warnings;
use File::Copy;
use File::Path qw(make_path);
use File::Basename qw(basename);
use File::Spec;
use Exporter "import";
use KarabinerGenerator::Config qw(get_paths);
use KarabinerGenerator::Validator qw(validate_files);
use JSON;

our @EXPORT_OK = qw(validate_complex_modifiers install_complex_modifiers);

sub validate_complex_modifiers {
    my ($file) = @_;
    return 0 unless -f $file;

    # First validate JSON structure
    my $json_text = do {
        local $/;
        open my $fh, '<', $file or return 0;
        <$fh>;
    };

    my $json_data;
    eval {
        $json_data = decode_json($json_text);
    };
    return 0 if $@ || !$json_data;

    # Validate required fields
    return 0 unless $json_data->{title} && ref($json_data->{rules}) eq 'ARRAY';

    # Skip CLI validation in test mode
    return 1 if $ENV{TEST_MODE};

    # Then validate with karabiner_cli
    my ($cli_path, undef, undef) = get_paths({global => {}});
    return validate_files($cli_path, $file);
}

sub install_complex_modifiers {
    my ($source_file, $dest_dir) = @_;
    return 0 unless -f $source_file;

    # Create destination directory if it doesn't exist
    eval {
        make_path($dest_dir);
    };
    return 0 if $@;

    my $dest_file = File::Spec->catfile($dest_dir, basename($source_file));

    # Copy the file
    return 0 unless copy($source_file, $dest_file);

    # Set permissions to match original
    eval {
        my $mode = (stat($source_file))[2] & 07777;
        chmod($mode, $dest_file);
    };

    return 1;
}

1;