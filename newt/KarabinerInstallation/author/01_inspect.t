# newt/KarabinerInstallation/author/inspect.t
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../../../lib";
use Data::Dumper;

# Skip test unless AUTHOR_TESTING is set
plan skip_all => "Author tests not required for installation"
    unless $ENV{AUTHOR_TESTING};

use KarabinerGenerator::KarabinerInstallation qw(find_karabiner_installation);

# Configure Data::Dumper
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Indent = 2;
$Data::Dumper::Terse = 1;

my $install_dir = find_karabiner_installation(required => 0);

if ($install_dir) {
    diag("\nKarabiner Installation Directory:");
    diag("-" x 40);
    diag($install_dir);
    diag("\nDirectory Contents:");
    diag("-" x 40);

    opendir(my $dh, $install_dir) or die "Can't open directory: $!";
    my @contents = sort grep { !/^\.\.?$/ } readdir($dh);
    closedir($dh);

    for my $item (@contents) {
        my $path = "$install_dir/$item";
        my $type = -d $path ? "Directory" : "File";
        diag(sprintf("%-10s %s", "[$type]", $item));
    }
} else {
    diag("\nNo Karabiner installation found");
}

# Always pass - this is an inspection test
pass("Completed installation directory inspection");
done_testing();