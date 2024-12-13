# File: t/00_load.t
use strict;
use warnings;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";

# Test that all modules load correctly
use_ok('KarabinerGenerator::Config');
use_ok('KarabinerGenerator::Terminal');
use_ok('KarabinerGenerator::Template');
use_ok('KarabinerGenerator::Validator');
use_ok('KarabinerGenerator::Installer');
use_ok('KarabinerGenerator::Utils');

done_testing;