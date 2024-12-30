# lib/KarabinerGenerator/JSONHandler.pm
package KarabinerGenerator::JSONHandler;

use strict;
use warnings;
use JSON;
use Carp qw(croak);
use File::Path qw(make_path);
use File::Basename qw(dirname);
use Exporter 'import';
use KarabinerGenerator::Validator qw(validate_files);
use KarabinerGenerator::Config qw(get_path);
use KarabinerGenerator::Init qw(db dbd);

our @EXPORT_OK = qw(
    read_json_file
    write_json_file
    validate_json
    decode_json
    encode_json
);

# Fixed order list for JSON keys
my @key_order = qw(
    title rules description manipulators type conditions from to key_code
    shell_command name value
);
my %key_order_map = map { $key_order[$_] => $_ } 0..$#key_order;

sub _ordered_keys {
    my ($hash) = @_;
    db("Sorting keys for hash");
    dbd($hash);
    return sort {
        ($key_order_map{$a} // 999) <=> ($key_order_map{$b} // 999)
        || $a cmp $b
    } keys %$hash;
}

sub _ordered_encode {
    my ($data, $indent_level) = @_;
    db("Encoding data with indent level: " . ($indent_level // 0));
    dbd($data);

    $indent_level //= 0;
    my $indent = "  " x $indent_level;
    my $next_indent = "  " x ($indent_level + 1);

    if (ref $data eq 'HASH') {
        db("Encoding hash");
        return "{\n" . join(",\n",
            map {
                $next_indent . JSON::encode_json("$_") . ': ' .
                _ordered_encode($data->{$_}, $indent_level + 1)
            } _ordered_keys($data)
        ) . "\n$indent}";
    }
    elsif (ref $data eq 'ARRAY') {
        db("Encoding array");
        return "[\n" . join(",\n",
            map { $next_indent . _ordered_encode($_, $indent_level + 1) } @$data
        ) . "\n$indent]";
    }
    else {
        db("Encoding scalar");
        return JSON::encode_json($data);
    }
}

sub read_json_file {
    my ($path_or_key) = @_;
    db("\n### ENTERING read_json_file() ###");
    db("Path or key: $path_or_key");

    my $file_path = $path_or_key =~ /\.json$/ ? $path_or_key : get_path($path_or_key);
    db("Resolved path: $file_path");

    croak "File does not exist: $file_path" unless -f $file_path;

    open my $fh, '<', $file_path or croak "Cannot open $file_path: $!";
    my $content = do { local $/; <$fh> };
    close $fh;

    db("Decoding JSON content");
    my $data = eval { decode_json($content) };
    croak "Failed to parse JSON from $file_path: $@" if $@;

    db("Successfully decoded JSON:");
    dbd($data);
    return $data;
}

sub write_json_file {
    my ($path_or_key, $data) = @_;
    db("\n### ENTERING write_json_file() ###");
    db("Path or key: $path_or_key");
    dbd($data);

    my $file_path = $path_or_key =~ /\.json$/ ? $path_or_key : get_path($path_or_key);
    db("Resolved path: $file_path");

    # Ensure output directory exists
    my $dir = dirname($file_path);
    make_path($dir) unless -d $dir;

    # Validate JSON structure
    db("Validating JSON structure");
    validate_json($data) or croak "Invalid JSON structure";

    # Write with pretty formatting
    db("Writing formatted JSON to file");
    open my $fh, '>', $file_path or croak "Cannot open $file_path for writing: $!";
    print $fh _ordered_encode($data);
    close $fh or croak "Cannot close $file_path: $!";

    # Validate using Karabiner CLI after writing
    db("Validating written file with Karabiner CLI");
    validate_files($file_path) or croak "Generated file failed Karabiner CLI validation";

    db("Successfully wrote and validated JSON file");
    return 1;
}

sub validate_json {
    my ($data) = @_;
    db("\n### ENTERING validate_json() ###");
    dbd($data);

    # Basic structure validation
    unless (ref $data eq 'HASH') {
        db("Validation failed: data is not a hash");
        return 0;
    }

    # Karabiner-specific validation
    if (exists $data->{rules}) {
        unless (ref $data->{rules} eq 'ARRAY') {
            db("Validation failed: rules is not an array");
            return 0;
        }

        for my $rule (@{$data->{rules}}) {
            unless (ref $rule eq 'HASH') {
                db("Validation failed: rule is not a hash");
                return 0;
            }
            unless (exists $rule->{description}) {
                db("Validation failed: rule missing description");
                return 0;
            }
            unless (exists $rule->{manipulators} && ref $rule->{manipulators} eq 'ARRAY') {
                db("Validation failed: invalid manipulators");
                return 0;
            }
        }
    }

    db("Validation passed");
    return 1;
}

1;