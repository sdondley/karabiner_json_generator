# 04_install.t - Test JSON file installation
use strict;
use warnings;
use Test::Most 'die';
use File::Basename;
use File::Spec;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
require "$RealBin/../../bin/json_generator.pl";
use KarabinerGenerator::Config qw(get_path);
use KarabinerGenerator::Init qw(init db);
use KarabinerGenerator::TestEnvironment::Loader qw(load_project_defaults load_karabiner_defaults load_test_fixtures);

# Setup test environment
init();
load_project_defaults();
load_karabiner_defaults();
load_test_fixtures();

# Run generator with install flag
my $generated_files = KarabinerGenerator::Generator->run(install => 1);

# Test directories exist
my $kb_dir = get_path('karabiner_dir');
ok($kb_dir && -d $kb_dir, "Karabiner test directory exists");

my $c_dir = get_path('karabiner_complex_mods_dir');
ok($c_dir && -d $c_dir, "Karabiner complex_modifications directory exists");

# Test files are installed
foreach my $file (@$generated_files) {
    my $basename = basename($file);
    my $installed_file = File::Spec->catfile($c_dir, $basename);
    ok(-f $installed_file, "Generated file $basename is installed");

    # Compare file contents
    my $orig_content = do { local $/; open my $fh, '<', $file or die "Can't read $file: $!"; <$fh> };
    my $inst_content = do { local $/; open my $fh, '<', $installed_file or die "Can't read $installed_file: $!"; <$fh> };
    is($inst_content, $orig_content, "Installed file $basename matches source");
}

done_testing();