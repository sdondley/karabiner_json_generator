# File: t/01_config.t
use strict;
use warnings;
use Test::More;
use Test::Exception;
use File::Temp qw(tempdir);
use FindBin qw($RealBin);
use lib "$RealBin/../lib";

use KarabinerGenerator::Config qw(load_config get_paths);

# Create temporary test files
my $tmp_dir = tempdir(CLEANUP => 1);

sub create_test_config {
    my ($content, $filename) = @_;
    open my $fh, '>', "$tmp_dir/$filename" or die $!;
    print $fh $content;
    close $fh;
}

# Test config loading
subtest 'Config Loading' => sub {
    create_test_config(q{
app_activators:
  title: "Test App Activators"
    }, 'config.yaml');

    create_test_config(q{
karabiner:
  config_dir: "~/.test-config"
    }, 'global_config.yaml');

    my $config = load_config("$tmp_dir/config.yaml");
    ok($config, 'Config loaded successfully');
    is($config->{app_activators}{title}, 'Test App Activators', 'Config values loaded correctly');
    ok($config->{global}, 'Global config merged');
};

# Test path resolution
subtest 'Path Resolution' => sub {
    my ($cli_path, $config_dir, $complex_mods_dir) = get_paths({
        karabiner => {
            config_dir => '~/.test-config'
        }
    });

    ok($cli_path, 'CLI path resolved');
    like($config_dir, qr/\.test-config$/, 'Config dir resolved');
    like($complex_mods_dir, qr/complex_modifications$/, 'Complex mods dir resolved');
};

done_testing;