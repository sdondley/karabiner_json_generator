# newt/Config/01_basic.t
use strict;
use warnings;
use Test::Most 'die';
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/../../lib";

use KarabinerGenerator::Config qw(get_home_directory get_path);
use KarabinerGenerator::Init qw(init is_test_mode);
use KarabinerGenerator::DebugUtils qw(db);

db("Starting basic config tests");

# First verify we're in test mode and initialize
ok(is_test_mode(), 'Running in test mode');
lives_ok(
    sub { init() },
    'Environment initialization completed'
);

subtest 'Home directory detection' => sub {
    db("Testing home directory detection");

    # Save original HOME environment variable
    my $original_home = $ENV{HOME};
    db("Original HOME: $original_home");

    # Test normal operation
    my $home = get_home_directory();
    db("Got home directory: $home");
    ok($home, 'Got home directory');
    ok(-d $home, 'Home directory exists');
    ok(-r $home, 'Home directory is readable');

    # Test with nonexistent path
    {
        db("Testing with nonexistent home directory");
        local $ENV{HOME} = '/nonexistent';

        # Test required parameter (should throw exception)
        db("Testing required=1 with nonexistent home");
        throws_ok(
            sub { get_home_directory(required => 1) },
            qr/Could not determine home directory/,
            'Throws error when required and home not found'
        );

        # Test optional mode
        db("Testing required=0 with nonexistent home");
        is(
            get_home_directory(required => 0),
            undef,
            'Returns undef when not required and home not found'
        );
    }

    # Restore original HOME
    $ENV{HOME} = $original_home;
    db("Restored HOME to: $original_home");
};

subtest 'Path resolution' => sub {
    db("Testing path resolution");
    my $home = get_home_directory();
    db("Using home directory: $home");

    my %paths_to_test = (
        config_dir => {
            desc => 'Config directory',
            pattern => qr/\Q$home\E/,
            message => 'includes home directory path'
        },
        karabiner_json => {
            desc => 'Karabiner.json path',
            pattern => qr/\Q$home\E.*karabiner\.json$/,
            message => 'includes home directory and ends with karabiner.json'
        },
        project_root => {
            desc => 'Project root',
            required => 1,
            check_exists => 1,
            message => 'exists and is accessible'
        },
        yaml_configs_dir => {
            desc => 'YAML configs directory',
            required => 1,
            check_parent => 1,
            message => 'parent directory exists'
        }
    );

    for my $path_key (sort keys %paths_to_test) {
        my $test_info = $paths_to_test{$path_key};
        db("Testing path: $path_key");

        my $path = get_path($path_key);
        db("Resolved path: $path");

        ok(defined $path, "$test_info->{desc} path is defined");

        if ($test_info->{pattern}) {
            like(
                $path,
                $test_info->{pattern},
                "$test_info->{desc} $test_info->{message}"
            );
        }

        if ($test_info->{check_exists}) {
            ok(-e $path, "$test_info->{desc} exists");
            ok(-r $path, "$test_info->{desc} is readable");
        }

        if ($test_info->{check_parent}) {
            my $parent = $path;
            $parent =~ s{/[^/]+$}{};
            ok(-d $parent, "Parent directory of $test_info->{desc} exists");
        }
    }

    # Test invalid path
    db("Testing invalid path handling");
    throws_ok(
        sub { get_path('nonexistent_path') },
        qr/Unknown resource: nonexistent_path/,
        'get_path throws error for unknown resource'
    );
};

done_testing();
db("Basic config tests completed");