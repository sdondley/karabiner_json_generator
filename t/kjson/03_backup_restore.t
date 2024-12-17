use strict;
use warnings;
use Test::Most;
use File::Temp qw(tempdir);
use File::Spec;
use File::Copy;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use JSON;

use KarabinerGenerator::KarabinerJsonFile qw(
    read_karabiner_json 
    write_karabiner_json 
    lint_karabiner_json
);

# Create a temp directory that will be automatically cleaned up
my $temp_dir = tempdir(CLEANUP => 1);

# Helper to create a valid karabiner.json file
sub create_valid_config {
    my ($file) = @_;
    my $config = {
        "global" => {
            "check_for_updates_on_startup" => 1,
            "show_in_menu_bar" => 1
        },
        "profiles" => [
            {
                "name" => "Default",
                "complex_modifications" => {
                    "rules" => [
                        {
                            "description" => "Test Rule",
                            "manipulators" => []
                        }
                    ]
                }
            }
        ]
    };
    
    open my $fh, '>', $file or die "Cannot create $file: $!";
    print $fh encode_json($config);
    close $fh;
    return $config;
}

# Helper to create an invalid karabiner.json file
sub create_invalid_config {
    my ($file) = @_;
    my $config = { 
        "profiles" => "not an array"
    };
    open my $fh, '>', $file or die "Cannot create $file: $!";
    print $fh encode_json($config);
    close $fh;
}

subtest 'Backup creation' => sub {
    my $test_file = File::Spec->catfile($temp_dir, 'karabiner.json');
    my $backup_file = "$test_file~";
    
    # Create initial valid config
    my $original_config = create_valid_config($test_file);
    
    # Try to write a modified config
    my $modified_config = {%$original_config};
    $modified_config->{profiles}[0]{name} = "Modified";
    
    lives_ok(
        sub { write_karabiner_json($modified_config, $test_file) },
        'Write with backup succeeds'
    );
    
    ok(-f $backup_file, 'Backup file was created');
    
    # Verify contents
    my $current = read_karabiner_json($test_file);
    is_deeply($current, $modified_config, 'Current file has modified content');
};

subtest 'Invalid config restoration' => sub {
    my $test_file = File::Spec->catfile($temp_dir, 'karabiner2.json');
    my $backup_file = "$test_file~";
    
    # Create initial valid config
    my $original_config = create_valid_config($test_file);
    
    # Create invalid config and attempt to write it
    my $invalid_config = { "profiles" => "not an array" };
    
    warning_like(
        sub { write_karabiner_json($invalid_config, $test_file) },
        qr/Invalid config structure/i,
        'Warning issued for invalid config'
    );
    
    ok(-f $test_file, 'Test file still exists');
    
    # Verify original content was retained
    my $current_content = read_karabiner_json($test_file);
    is_deeply($current_content, $original_config, 'Original config was preserved');
    
    ok(!-f $backup_file, 'Backup file was cleaned up');
};

subtest 'Multiple writes' => sub {
    my $test_file = File::Spec->catfile($temp_dir, 'karabiner3.json');
    
    # Create initial config
    my $config1 = create_valid_config($test_file);
    
    # First modification
    my $config2 = {%$config1};
    $config2->{profiles}[0]{name} = "Modified1";
    lives_ok(
        sub { write_karabiner_json($config2, $test_file) },
        'First modification succeeds'
    );
    
    my $after_first = read_karabiner_json($test_file);
    is_deeply($after_first, $config2, 'First modification was written correctly');
    
    # Second modification
    my $config3 = {%$config2};
    $config3->{profiles}[0]{name} = "Modified2";
    lives_ok(
        sub { write_karabiner_json($config3, $test_file) },
        'Second modification succeeds'
    );
    
    my $after_second = read_karabiner_json($test_file);
    is_deeply($after_second, $config3, 'Second modification was written correctly');
};

done_testing();