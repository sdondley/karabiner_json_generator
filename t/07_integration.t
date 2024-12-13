# File: t/07_integration.t
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::Spec;
use JSON;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";

BEGIN { $ENV{TEST_MODE} = 1; }

use KarabinerGenerator::Config qw(load_config);
use KarabinerGenerator::Template qw(process_templates);

# Create temp test environment with subdirectories
my $temp_dir = tempdir(CLEANUP => 1);
my $template_dir = File::Spec->catdir($temp_dir, 'templates');
my $output_dir = File::Spec->catdir($temp_dir, 'generated_json');
make_path($template_dir, $output_dir);

# Test complete pipeline
subtest 'Template Processing Pipeline' => sub {
    # Create test config with app_activators structure
    my $config_content = qq{
app_activators:
  title: "Test App Activators"
  shell_command: "/test/path/script.sh"
  modifiers:
    double_tap_rshift:
      apps:
        - trigger_key: "s"
          app_name: "Safari"
        - trigger_key: "c"
          app_name: "Chrome"
    };

    my $config_file = File::Spec->catfile($temp_dir, 'config.yaml');
    open my $config_fh, '>', $config_file or die "Cannot create config file: $!";
    print $config_fh $config_content;
    close $config_fh;

    # Create test template matching app_activators structure
    my $template_content = q{
{
  "title": "[% title %]",
  "rules": [
    [%- SET first = 1 -%]
    [%- FOREACH app IN modifiers.double_tap_rshift.apps -%]
    [%- IF !first %],[% END -%]
    [%- SET first = 0 -%]
    {
      "description": "Double tap right shift-[% app.trigger_key %] to [% app.app_name %]",
      "manipulators": [{
        "type": "basic",
        "conditions": [{
          "type": "variable_if",
          "name": "double_tap_rshift",
          "value": 2
        }],
        "from": {
          "key_code": "[% app.trigger_key %]"
        },
        "to": [{
          "shell_command": "[% shell_command %] '[% app.app_name %]'"
        }]
      }]
    }
    [%- END -%]
  ]
}
    };

    my $template_file = File::Spec->catfile($template_dir, 'app_activators_dtrs.json.tpl');
    open my $template_fh, '>', $template_file or die "Cannot create template file: $!";
    print $template_fh $template_content;
    close $template_fh;

    plan tests => 9;

    # Load config
    my $config = load_config($config_file);
    ok($config, 'Configuration loaded');
    ok($config->{app_activators}, 'Config contains expected data');

    # Process templates
    my @generated_files = process_templates($template_dir, $config, $output_dir);
    ok(@generated_files, 'Files were generated');
    is(scalar @generated_files, 1, 'One file was generated');
    ok(-f $generated_files[0], 'Generated file exists');

    # Validate generated file
    open my $json_fh, '<', $generated_files[0] or die "Cannot read generated file: $!";
    my $json_content = do { local $/; <$json_fh> };
    close $json_fh;

    my $data = decode_json($json_content);

    # Structure tests
    is($data->{title}, 'Test App Activators', 'Title was properly templated');
    is(scalar @{$data->{rules}}, 2, 'Generated correct number of rules');

    my $safari_rule = $data->{rules}[0];
    my $chrome_rule = $data->{rules}[1];

    like($safari_rule->{manipulators}[0]{to}[0]{shell_command}, qr{/test/path/script\.sh 'Safari'}, 'Safari command correct');
    like($chrome_rule->{manipulators}[0]{to}[0]{shell_command}, qr{/test/path/script\.sh 'Chrome'}, 'Chrome command correct');
};

# Test empty modifier handling
subtest 'Empty Complex Modifier Handling' => sub {
    plan tests => 4;

    # Create test configs - one with entries, one without
    my $config_with_entries = qq{
app_activators:
  title: "Test App Activators"
  shell_command: "/test/path/script.sh"
  modifiers:
    double_tap_rshift:
      apps:
        - trigger_key: "s"
          app_name: "Safari"
    };

    my $config_without_entries = qq{
app_activators:
  title: "Test App Activators"
  shell_command: "/test/path/script.sh"
  modifiers:
    double_tap_rshift:
      apps: []
    };

    my $config_file = File::Spec->catfile($temp_dir, 'config.yaml');

    # Create template for double tap right shift
    my $template_content = q{
{
  "title": "[% title %]",
  "rules": [
    [%- FOREACH app IN modifiers.double_tap_rshift.apps -%]
    {
      "description": "Double tap right shift-[% app.trigger_key %] to [% app.app_name %]",
      "manipulators": [{
        "type": "basic",
        "conditions": [{
          "type": "variable_if",
          "name": "double_tap_rshift",
          "value": 2
        }],
        "from": {
          "key_code": "[% app.trigger_key %]"
        },
        "to": [{
          "shell_command": "[% shell_command %] '[% app.app_name %]'"
        }]
      }]
    }[% IF !loop.last %],[% END %]
    [%- END -%]
  ]
}
    };

    my $template_file = File::Spec->catfile($template_dir, 'app_activators_dtrs.json.tpl');
    open my $template_fh, '>', $template_file or die "Cannot create template file: $!";
    print $template_fh $template_content;
    close $template_fh;

    # Test with entries
    {
        open my $fh, '>', $config_file or die "Cannot create config file: $!";
        print $fh $config_with_entries;
        close $fh;

        my @files = process_templates($template_dir, load_config($config_file), $output_dir);
        ok(@files > 0, "Files generated when entries exist");
        ok(-f $files[0], "Generated file exists");
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

        my @files = process_templates($template_dir, load_config($config_file), $output_dir);
        is(scalar @files, 0, "No files generated for empty config");
        ok(!-f $empty_file, "Previous file removed when config is empty");
    }
};

done_testing();