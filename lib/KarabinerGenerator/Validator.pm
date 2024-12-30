package KarabinerGenerator::Validator;
use strict;
use warnings;
use Exporter "import";
use KarabinerGenerator::Terminal qw(fmt_print);
use KarabinerGenerator::Config qw(get_path);
use KarabinerGenerator::CLI qw(run_ke_cli_cmd);
use KarabinerGenerator::Init qw(is_test_mode);

our @EXPORT_OK = qw(validate_files);

sub validate_files {
    my (@files) = @_;
    my @failed_files;


    foreach my $file (@files) {
        unless (-f $file) {
            warn "File does not exist: $file" unless is_test_mode();
            push @failed_files, $file;
            next;
        }

        my ($result, $so, $se) = run_ke_cli_cmd(['--lint-complex-modifications', $file]);

        # Check results
        if ($result->{status} != 0 || $result->{stderr} =~ /error|invalid|failed/i) {
            push @failed_files, $file;
            next;
        }
    }


    if (@failed_files) {
        print fmt_print("Validation failed for: \n", 'error') unless $ENV{QUIET};
        for my $file (@failed_files) {
            print fmt_print(" - $file\n", 'error') unless $ENV{QUIET};
        }
        return 0;
    }

    return 1;
}

1;