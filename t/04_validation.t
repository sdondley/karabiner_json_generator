# File: t/04_validator.t
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use FindBin qw($RealBin);
use lib "$RealBin/../lib";

use KarabinerGenerator::Validator qw(validate_files);

# Test validation
subtest 'File Validation' => sub {
    my $tmp_dir = tempdir(CLEANUP => 1);
    
    # Create test JSON file
    open my $fh, '>', "$tmp_dir/test.json" or die $!;
    print $fh q{
        {"title": "Test", "rules": []}
    };
    close $fh;
    
    my $is_valid = validate_files(
        '/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli',
        "$tmp_dir/test.json"
    );
    
    ok(defined $is_valid, 'Validation returns result');
};

done_testing;