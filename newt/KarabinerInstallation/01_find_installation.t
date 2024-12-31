# newt/KarabinerInstallation/01_find_installation.t
use strict;
use warnings;
use Test::Most 'die';
use Test::Exception;
use File::Spec;

use KarabinerGenerator::KarabinerInstallation qw(find_karabiner_installation);

# Test finding installation
subtest 'Installation detection' => sub {
    my $install_info = find_karabiner_installation(required => 0);

    SKIP: {
        skip "Karabiner-Elements not installed", 4 unless $install_info;

        ok($install_info, 'Found Karabiner installation information');
        ok(-d $install_info->{config_dir}, 'Config directory exists');
        ok(-f $install_info->{cli_path}, 'CLI exists');
        ok(-x $install_info->{cli_path}, 'CLI is executable');
    }
};

# Test error conditions
subtest 'Error handling' => sub {
    # Temporarily modify HOME to test missing installation
    local $ENV{HOME} = '/nonexistent/path';

    throws_ok(
        sub { find_karabiner_installation(required => 1) },
        qr/Could not find valid Karabiner installation/,
        'Throws error when required and not found'
    );

    is(
        find_karabiner_installation(required => 0),
        undef,
        'Returns undef when not required and not found'
    );
};

done_testing();