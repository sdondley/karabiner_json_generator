use strict;
use warnings;
use Test::Most tests => 6, 'die';
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use File::Spec;
use File::Temp qw(tempdir);
use JSON;

# Test module loading
use_ok('KarabinerGenerator::KarabinerJsonFile', qw(
    read_karabiner_json 
    write_karabiner_json 
    get_profile_names 
    get_current_profile_rules
));

use KarabinerGenerator::Config qw(mode get_path);

# Set test mode
BEGIN {
    mode('test');
}

# Load expected JSON data for comparison
my $fixture_path = get_path('karabiner_json');
my $expected_json = do {
    open(my $fh, '<', $fixture_path) or die "Cannot read fixture: $!";
    local $/;
    my $json_text = <$fh>;
    decode_json($json_text);
};

# Test reading the file
my $config = read_karabiner_json();  # No need to pass path, will use Config.pm default
cmp_deeply(
    $config,
    $expected_json,
    'Loaded JSON matches fixture exactly'
);

# Test getting profile names
my $profiles = get_profile_names($config);
cmp_deeply(
    $profiles,
    ['Default', 'Test', 'Generated Json'],
    'Profile names extracted correctly'
);

# Test getting rules for a specific profile
my $rules = get_current_profile_rules($config, 'Default');
cmp_deeply(
    $rules,
    [
        {
            "description" => "Test Rule 1",
            "manipulators" => []
        }
    ],
    'Rules extracted correctly for Default profile'
);

# Test error cases
subtest 'Read error cases' => sub {
    plan tests => 3;
    
    # Create a temp path for non-existent file test
    my $nonexistent_path = path_in(get_path('config_dir'), 'nonexistent.json');
    
    # Test reading non-existent file
    throws_ok(
        sub { read_karabiner_json($nonexistent_path) },
        qr/Cannot read karabiner.json: No such file or directory/,
        'Throws error for non-existent file'
    );

    # Test with invalid profile name
    is(
        get_current_profile_rules($config, 'NonexistentProfile'),
        undef,
        'Returns undef for non-existent profile'
    );

    # Test with invalid JSON structure
    my $invalid_file = path_in(get_path('config_dir'), 'invalid.json');
    open(my $fh, '>', $invalid_file) or die "Cannot create test file: $!";
    print $fh encode_json({ "profiles" => "not an array" });
    close($fh);

    throws_ok(
        sub { read_karabiner_json($invalid_file) },
        qr/Invalid karabiner.json structure/,
        'Throws error for invalid JSON structure'
    );
};

# Test writing functionality
subtest 'Write functionality' => sub {
    plan tests => 2;
    
    my $test_output = path_in(get_path('config_dir'), 'test_write.json');
    
    # Test writing valid config
    lives_ok(
        sub { write_karabiner_json($config, $test_output) },
        'Successfully wrote config file'
    );
    
    # Verify written content
    my $written_config = read_karabiner_json($test_output);
    cmp_deeply(
        $written_config,
        $config,
        'Written config matches original'
    );
};

# Helper function for path construction (from Config.pm)
sub path_in {
    my ($base_path, @components) = @_;
    return File::Spec->catfile($base_path, @components) if $components[-1] =~ /\./;
    return File::Spec->catdir($base_path, @components);
}