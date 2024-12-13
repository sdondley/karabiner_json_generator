package KarabinerGenerator::Validator;
use strict;
use warnings;
use Exporter "import";

our @EXPORT_OK = qw(validate_files);

sub validate_files {
    my ($cli_path, @files) = @_;
    my $all_valid = 1;

    foreach my $file (@files) {
        # Skip validation in test mode
        if ($ENV{TEST_MODE}) {
            next;
        }

        # Use system() with LIST form to avoid shell interpretation
        my $result;
        if ($ENV{QUIET}) {
            # Redirect both stdout and stderr to null in quiet mode
            open my $oldout, ">&STDOUT" or die "Can't dup STDOUT: $!";
            open my $olderr, ">&STDERR" or die "Can't dup STDERR: $!";
            open STDOUT, '>', File::Spec->devnull() or die "Can't open null: $!";
            open STDERR, '>', File::Spec->devnull() or die "Can't open null: $!";

            $result = system($cli_path, '--lint-complex-modifications', $file);

            open STDOUT, ">&", $oldout or die "Can't restore STDOUT: $!";
            open STDERR, ">&", $olderr or die "Can't restore STDERR: $!";
        } else {
            $result = system($cli_path, '--lint-complex-modifications', $file);
        }

        $all_valid = 0 if $result != 0;
    }

    return $all_valid;
}

1;