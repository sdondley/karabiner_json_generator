# File: t/05_installer.t
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use FindBin qw($RealBin);
use lib "$RealBin/../lib";

use KarabinerGenerator::Installer qw(install_files);

# Test installation
subtest 'File Installation' => sub {
    my $source_dir = tempdir(CLEANUP => 1);
    my $dest_dir = tempdir(CLEANUP => 1);
    
    # Create test file
    open my $fh, '>', "$source_dir/test.json" or die $!;
    print $fh "test content";
    close $fh;
    
    my $result = install_files($dest_dir, "$source_dir/test.json");
    ok($result, 'Installation completes');
    ok(-f "$dest_dir/test.json", 'File copied to destination');
};

done_testing;