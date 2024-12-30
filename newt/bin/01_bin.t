use strict;
use warnings;
use FindBin qw($RealBin);
use File::Temp qw(tempfile);
use lib "$RealBin/../../lib";
use KarabinerGenerator::Init qw(init);
use Test::Most 'die', tests => 1;

init();

require "$RealBin/../../bin/json_generator.pl";
# Redirect STDOUT to the temporary file
my $output = KarabinerGenerator::Generator->run(help => 1);

# Capture specific help sections instead of debug messages
like($output, qr/Options:.*--help.*--debug/s, 'Options shown');

done_testing();