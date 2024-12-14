package KarabinerGenerator::Template;
use strict;
use warnings;
use Template;
use JSON;
use File::Path qw(make_path);
use File::Basename qw(basename fileparse);
use File::Spec;
use Carp qw(croak);
use Data::Dumper;
use KarabinerGenerator::Terminal qw(fmt_print);  # Add this import
use Exporter "import";

our @EXPORT_OK = qw(process_templates);

sub _debug {
    return if $ENV{TEST_MODE};
    my $msg = shift;
    warn "DEBUG: $msg\n" if $ENV{DEBUG} && !$ENV{QUIET};
}

sub _info {
    return if $ENV{TEST_MODE};
    my $msg = shift;
    warn "$msg\n" unless $ENV{QUIET};
}

# Fixed order list for JSON keys
my @key_order = qw(
    title rules description manipulators type conditions from to key_code shell_command name value
);
my %key_order_map = map { $key_order[$_] => $_ } 0..$#key_order;

sub _ordered_keys {
    my ($hash) = @_;
    return sort {
        ($key_order_map{$a} // 999) <=> ($key_order_map{$b} // 999)
        || $a cmp $b
    } keys %$hash;
}

sub _ordered_encode {
    my ($data, $indent_level) = @_;
    $indent_level //= 0;
    my $indent = "  " x $indent_level;
    my $next_indent = "  " x ($indent_level + 1);

    if (ref $data eq 'HASH') {
        return "{\n" . join(",\n",
            map {
                $next_indent . JSON::encode_json("$_") . ': ' .
                _ordered_encode($data->{$_}, $indent_level + 1)
            } _ordered_keys($data)
        ) . "\n$indent}";
    }
    elsif (ref $data eq 'ARRAY') {
        return "[\n" . join(",\n",
            map { $next_indent . _ordered_encode($_, $indent_level + 1) } @$data
        ) . "\n$indent]";
    }
    else {
        return JSON::encode_json($data);
    }
}

sub process_templates {
    my ($template_dir, $config, $output_dir) = @_;

    # Validate input parameters
    return () unless $template_dir && $config && $output_dir;
    return () unless -d $template_dir;

    # Create output directory if it doesn't exist
    make_path($output_dir) unless -d $output_dir;

    # Initialize Template Toolkit
    my $tt = Template->new({
        ABSOLUTE => 1,
        RELATIVE => 1,
        EVAL_PERL => 0
    }) or croak "Template initialization failed: $Template::ERROR\n";

    # Get list of template files
    opendir(my $dh, $template_dir) or croak "Cannot open template directory: $!\n";
    my @template_files = grep { /\.json\.tpl$/ } readdir($dh);
    closedir($dh);

    my @generated_files;

    foreach my $template_file (@template_files) {
        my ($base_name, undef, undef) = fileparse($template_file, qr/\.json\.tpl$/);
        my $output_file = File::Spec->catfile($output_dir, "$base_name.json");

        # Handle both production and test configs
        my $template_config = $config;
        if ($config->{app_activators}) {
            $template_config = $config->{app_activators};
        }

        # Skip empty templates in production
        if ($base_name =~ /^app_activators_/) {
            my $modifier_type = $base_name;
            $modifier_type =~ s/^app_activators_//;

            if ($template_config->{modifiers}) {
                my $has_entries = 0;
                if ($modifier_type eq 'dtrs') {
                    $has_entries = exists $template_config->{modifiers}{double_tap_rshift}{apps} &&
                                 @{$template_config->{modifiers}{double_tap_rshift}{apps}} > 0;
                }
                elsif ($modifier_type eq 'dtls') {
                    $has_entries = exists $template_config->{modifiers}{double_tap_lshift}{apps} &&
                                 @{$template_config->{modifiers}{double_tap_lshift}{apps}} > 0;
                }
                elsif ($modifier_type eq 'lrs') {
                    $has_entries = exists $template_config->{modifiers}{lr_shift}{quick_press} &&
                                 @{$template_config->{modifiers}{lr_shift}{quick_press}} > 0;
                }
                elsif ($modifier_type eq 'rls') {
                    $has_entries = exists $template_config->{modifiers}{rl_shift}{quick_press} &&
                                 @{$template_config->{modifiers}{rl_shift}{quick_press}} > 0;
                }

                if (!$has_entries) {
                    unlink $output_file if -f $output_file;
                    next;
                }
            }
        }

        # Read and process template
        open(my $tfh, '<', File::Spec->catfile($template_dir, $template_file))
            or croak "Cannot open template $template_file: $!\n";
        my $template_content = do { local $/; <$tfh> };
        close($tfh);

        my $output;
        unless ($tt->process(\$template_content, $template_config, \$output)) {
            croak "Template processing failed: " . $tt->error() . "\n";
        }

        my $json_obj;
        eval {
            $json_obj = decode_json($output);
        };
        if ($@) {
            croak "JSON parsing error in $template_file: $@\n";
        }

        open(my $fh, '>', $output_file)
            or croak "Cannot open output file $output_file: $!\n";
        print $fh _ordered_encode($json_obj);
        close($fh);

        print fmt_print("Generated $output_file", 'success'), "\n" unless $ENV{TEST_MODE} || $ENV{QUIET};

        push @generated_files, $output_file;
    }

    return @generated_files;
}

1;