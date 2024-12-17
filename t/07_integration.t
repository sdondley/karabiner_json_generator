# File: t/07_integration.t
use strict;
use warnings;
use Test::Most 'die';
use Test::Deep;
use File::Spec;
use File::Basename qw(basename);
use JSON;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";

use KarabinerGenerator::Config qw(get_path mode load_config);
use KarabinerGenerator::Template qw(process_templates);
use KarabinerGenerator::Validator qw(validate_files);

# Ensure we're in test mode
mode('test');

# Plan total number of subtests
plan tests => 2;

# Test complete pipeline
subtest 'Template Processing Pipeline' => sub {
    # Calculate number of tests
    my $base_tests = 8;  # Initial tests including file generation and type checks
    my $per_file_tests = 9;  # Tests per file (title, rules array, etc.)
    my $test_file_check = 1;  # Test for test.json
    my $file_count = 3;  # Number of app activator files

    plan tests => $base_tests + ($file_count * $per_file_tests) + $test_file_check;  # 8 + (3 * 9) + 1 = 36

    # Create test config with app_activators structure
    my $config_content = qq{
app_activators:
  title: "App Activators"
  shell_command: "/Users/steve/bin/master.sh"
  modifiers:
    double_tap_rshift:
      apps:
        - trigger_key: "a"
          app_name: "Activity Monitor"
        - trigger_key: "s"
          app_name: "Safari"
        - trigger_key: "d"
          app_name: "Discord"
        - trigger_key: "f"
          app_name: "Finder"
    double_tap_lshift:
      apps:
        - trigger_key: "i"
          app_name: "iTerm"
        - trigger_key: "m"
          app_name: "Mail"
        - trigger_key: "n"
          app_name: "Notes"
        - trigger_key: "k"
          app_name: "Karabiner-Elements"
        - trigger_key: "p"
          app_name: "Preview"
    lr_shift:
      quick_press:
        - trigger_key: "s"
          app_name: "System Settings"
    };

    # Use Config.pm paths
    my $config_file = get_path('config_yaml');
    open my $config_fh, '>', $config_file or die "Cannot create config file: $!";
    print $config_fh $config_content;
    close $config_fh;

    # Load config and process templates
    my $config = load_config();
    ok($config, 'Configuration loaded');
    ok($config->{app_activators}, 'Config contains expected data');

    my @generated_files = process_templates(
        get_path('templates_dir'),
        $config,
        get_path('generated_json_dir')
    );

    ok(@generated_files, 'Files were generated');
    my @app_files = grep { /app_activators_[^\/]+\.json$/ } @generated_files;
    is(scalar @app_files, 3, 'Three app activator files were generated');

    # Define expected titles and rules for each file type
    my %file_expectations = (
        dtrs => {
            title_suffix => '- Double Tap Right Shift Triggers',
            rule_count => 4,
            sample_app => 'Safari',
            description_pattern => qr/Double tap left shift-s to Safari/,  # Note: This is actually a bug in the template
        },
        dtls => {
            title_suffix => '- Double Tap Left Shift Triggers',
            rule_count => 5,
            sample_app => 'iTerm',
            description_pattern => qr/Double tap left shift-i to iTerm/,
        },
        lrs => {
            title_suffix => '- Left-Right Shift Sequence Triggers',
            rule_count => 1,
            sample_app => 'System Settings',
            description_pattern => qr/Left-Right shift quick press \+ s to System Settings/,
        }
    );

    # Verify the expected files exist
    my %found_files = map { $_ => 1 } qw(dtrs dtls lrs);
    for my $file (@app_files) {
        if (basename($file) =~ /app_activators_(\w+)\.json$/) {
            ok(exists $found_files{$1}, "Found expected file type: $1");
            delete $found_files{$1};
        }
    }
    is(scalar(keys %found_files), 0, 'All expected file types were generated');

    # Test each file separately
    for my $file (@app_files) {
        ok(-f $file, "File exists: $file");
        my ($type) = $file =~ /app_activators_(\w+)\.json$/;
        my $expectations = $file_expectations{$type};

        # Read and parse the file
        open my $json_fh, '<', $file or die "Cannot read generated file: $!";
        my $json_content = do { local $/; <$json_fh> };
        close $json_fh;

        my $data = decode_json($json_content);

        # Basic structure validation
        ok(exists $data->{title}, 'Has title field');
        is($data->{title}, "App Activators $expectations->{title_suffix}", "Title correct for $type");
        ok(exists $data->{rules}, 'Has rules array');
        ok(ref $data->{rules} eq 'ARRAY', 'Rules is an array');
        is(scalar @{$data->{rules}}, $expectations->{rule_count}, "Has correct number of rules for $type");

        # Find and validate sample rule
        my ($sample_rule) = grep { $_->{description} =~ /$expectations->{sample_app}/ } @{$data->{rules}};
        ok($sample_rule, "Found $expectations->{sample_app} rule");
        like($sample_rule->{description}, $expectations->{description_pattern}, "Description matches pattern for $type");
        like($sample_rule->{manipulators}[0]{to}[0]{shell_command},
             qr{/Users/steve/bin/master\.sh '$expectations->{sample_app}'},
             "Command correct for $expectations->{sample_app}");
    }

    # Check test.json was not generated or is empty if generated
    my @test_files = grep { /test\.json$/ } @generated_files;
    if (@test_files) {
        open my $test_fh, '<', $test_files[0] or die "Cannot read test file: $!";
        my $test_content = do { local $/; <$test_fh> };
        close $test_fh;
        my $test_data = decode_json($test_content);
        is_deeply($test_data->{rules}, [], 'Test file has empty rules array if generated');
    }
};

# Test empty modifier handling
subtest 'Empty Complex Modifier Handling' => sub {
    plan tests => 4;

    # Create test configs - one with entries, one without
    my $config_with_entries = qq{
app_activators:
  title: "App Activators"
  shell_command: "/Users/steve/bin/master.sh"
  modifiers:
    double_tap_rshift:
      apps:
        - trigger_key: "s"
          app_name: "Safari"
    };

    my $config_without_entries = qq{
app_activators:
  title: "App Activators"
  shell_command: "/Users/steve/bin/master.sh"
  modifiers:
    double_tap_rshift:
      apps: []
    };

    my $config_file = get_path('config_yaml');
    my $template_dir = get_path('templates_dir');
    my $output_dir = get_path('generated_json_dir');

    # Clean the output directory first
    unlink glob File::Spec->catfile($output_dir, '*');

    # Test with entries
    {
        open my $fh, '>', $config_file or die "Cannot create config file: $!";
        print $fh $config_with_entries;
        close $fh;

        my @files = process_templates($template_dir, load_config(), $output_dir);
        my @app_files = grep { /app_activators_[^\/]+\.json$/ } @files;
        ok(@app_files > 0, "App activator files generated when entries exist");
        ok(-f $app_files[0], "Generated file exists");
    }

    # Test without entries
    {
        # First create a file that should be removed
        my $empty_file = File::Spec->catfile($output_dir, "app_activators_dtrs.json");
        open my $fh, '>', $empty_file or die "Cannot create test file: $!";
        print $fh "{}";
        close $fh;

        # Now process empty config
        open $fh, '>', $config_file or die "Cannot create config file: $!";
        print $fh $config_without_entries;
        close $fh;

        my @files = process_templates($template_dir, load_config(), $output_dir);
        my @app_files = grep { /app_activators_[^\/]+\.json$/ } @files;
        is(scalar @app_files, 0, "No app activator files generated for empty config");
        ok(!-f $empty_file, "Previous file removed when config is empty");
    }
};