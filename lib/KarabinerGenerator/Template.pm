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

        # Read template file
        open(my $tfh, '<', File::Spec->catfile($template_dir, $template_file))
            or croak "Cannot open template $template_file: $!\n";
        local $/;
        my $template_content = <$tfh>;
        close($tfh);

        # Process template
        my $output;
        my $template_vars = $config;

        unless ($tt->process(\$template_content, $template_vars, \$output)) {
            croak "Template processing failed: " . $tt->error() . "\n";
        }

        # Validate and format JSON
        my $json_obj;
        eval {
            $json_obj = decode_json($output);
        };
        if ($@) {
            croak "JSON parsing error in $template_file: $@\n";
        }

        # Create output file path
        my $output_file = File::Spec->catfile($output_dir, "$base_name.json");

        # Write formatted JSON to output file
        open(my $fh, '>', $output_file)
            or croak "Cannot open output file $output_file: $!\n";
        print $fh JSON->new->pretty->canonical->encode($json_obj);
        close($fh);

        push @generated_files, $output_file;
    }

    return @generated_files;
}

1;