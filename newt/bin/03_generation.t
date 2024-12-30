use strict;
use warnings; 
use Test::More;
use Capture::Tiny qw(capture);
use File::Find;
use File::Basename;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
require "$RealBin/../../bin/json_generator.pl";
use KarabinerGenerator::Config qw(get_path);
use KarabinerGenerator::Init qw(init db);
use KarabinerGenerator::TestEnvironment::Loader qw(load_project_defaults load_karabiner_defaults load_test_fixtures);


init();
load_project_defaults();

KarabinerGenerator::Generator->run();
my $temp_dir = get_path('project_dir');

db $temp_dir;

ok($temp_dir && -d $temp_dir, "Test directory exists");

my $triggers_dir = "$temp_dir/generated_json/triggers";
ok(-f "$triggers_dir/app_activators_dtls.json", "DTLS file exists");

done_testing();