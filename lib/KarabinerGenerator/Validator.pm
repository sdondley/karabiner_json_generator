package KarabinerGenerator::Validator;
use strict;
use warnings;
use File::Spec;
use Exporter "import";
use KarabinerGenerator::Terminal qw(fmt_print);

our @EXPORT_OK = qw(validate_files);

sub validate_files {
    my ($cli_path, @files) = @_;
    my @failed_files;

    foreach my $file (@files) {
        unless (-f $file) {
            warn "File does not exist: $file" unless $ENV{QUIET};
            push @failed_files, $file;
            next;
        }

        print fmt_print("Validating $file... \n", 'info') unless $ENV{QUIET};

        # Use karabiner_cli to validate
        my $result;
        if ($ENV{QUIET}) {
            $result = system("'$cli_path' --lint-complex-modifications $file >/dev/null 2>&1");
        } else {
            $result = system("'$cli_path' --lint-complex-modifications $file >/dev/null");
        }

        if ($result != 0) {
            print fmt_print("failed", 'error'), "\n" unless $ENV{QUIET};
            push @failed_files, $file;
        }
        # Remove the extra "ok" print here - karabiner_cli already prints it
    }

    if (@failed_files) {
        print fmt_print("Validation failed for: \n", 'error') unless $ENV{QUIET};
        for my $file (@failed_files) {
            print fmt_print(" - $file\n", 'error') unless $ENV{QUIET};
        }
        return 0;
    }

    print fmt_print("All files passed validation\n", 'success') unless $ENV{QUIET};
    return 1;
}

1;