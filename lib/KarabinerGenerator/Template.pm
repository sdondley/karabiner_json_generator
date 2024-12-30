# lib/KarabinerGenerator/Template.pm
package KarabinerGenerator::Template;

use strict;
use warnings;
use Template;
use File::Path qw(make_path);
use File::Basename qw(basename fileparse dirname);
use File::Find qw(find);
use File::Spec;
use Carp qw(croak);
use Exporter "import";
use KarabinerGenerator::DebugUtils qw(db);
use KarabinerGenerator::Config qw(get_path);
use KarabinerGenerator::Init qw(is_test_mode);
use KarabinerGenerator::JSONHandler qw(
    read_json_file
    write_json_file
    validate_json
    decode_json
);

our @EXPORT_OK = qw(process_templates);

sub _get_output_dir {
    my ($template_path) = @_;

    # Check which template dir we're in
    for my $type (qw(triggers complex_mods common)) {
        my $template_dir = get_path("${type}_templates_dir");
        if (index($template_path, $template_dir) == 0) {
            my $output_type = $type eq 'common' ? 'triggers' : $type;
            return get_path("generated_${output_type}_dir");
        }
    }

    croak "Template not in a valid template directory: $template_path";
}

sub process_templates {
    my ($config) = @_;
    db("\n### ENTERING process_templates() ###");

    my $template_dir = get_path('templates_dir');
    db("template_dir: $template_dir");

    return () unless $template_dir && $config;
    return () unless -d $template_dir;

    my $tt = Template->new({
        ABSOLUTE => 1,
        RELATIVE => 1,
        EVAL_PERL => 0
    }) or croak "Template initialization failed: $Template::ERROR\n";

    my @template_files;
    my @generated_files;

    find(
        {
            wanted => sub {
                return if /^\./; # Skip hidden files/dirs
                return unless -f && /\.json\.tpl$/;
                push @template_files, $File::Find::name;
            },
            preprocess => sub { grep { !/^\./ } @_ }, # Skip hidden directories during traversal
            no_chdir => 1
        },
        $template_dir
    );

    for my $template_file (@template_files) {
        my ($base_name, undef, undef) = fileparse($template_file, qr/\.json\.tpl$/);

        my $actual_output_dir = _get_output_dir($template_file);
        make_path($actual_output_dir) unless -d $actual_output_dir;

        my $output_file = File::Spec->catfile($actual_output_dir, "$base_name.json");

        open(my $tfh, '<', $template_file)
            or croak "Cannot open template $template_file: $!\n";
        my $template_content = do { local $/; <$tfh> };
        close($tfh);

        my $output;
        unless ($tt->process(\$template_content, $config, \$output)) {
            croak "Template processing failed for $template_file: " . $tt->error() . "\n";
        }

        my $json_obj = eval { decode_json($output) };
        if ($@) {
            croak "JSON parsing error in $template_file: $@\nOutput was: $output\n";
        }

        write_json_file($output_file, $json_obj)
            or croak "Failed to write JSON to $output_file";

        db("Generated file: $output_file");
        push @generated_files, $output_file;
    }

    return @generated_files;
}

1;