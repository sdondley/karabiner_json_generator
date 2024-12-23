use strict;
use warnings;
use Test::More;
use Test::Deep;
use File::Temp qw(tempdir);
use File::Spec;
use File::Path qw(make_path);
use FindBin qw($RealBin);
use lib "$RealBin/../lib";
use JSON;

use KarabinerGenerator::Config qw(load_config get_path mode);
use KarabinerGenerator::Template qw(process_templates);

# Set test mode
mode('test');

# Get paths from Config.pm
my $template_dir = get_path('templates_dir');
my $output_dir = get_path('generated_json_dir');
my $config_file = get_path('config_yaml');

# Create test config with specifically ordered properties
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

# Create config file
open my $config_fh, '>', $config_file or die "Cannot create config file: $!";
print $config_fh $config_content;
close $config_fh;

# Create template with specific property order
my $template_content = q{
{
  "title": "[% app_activators.title %]",
  "rules": [
    {
      "description": "Double tap right shift-[% app_activators.modifiers.double_tap_rshift.apps.0.trigger_key %] to [% app_activators.modifiers.double_tap_rshift.apps.0.app_name %]",
      "manipulators": [{
        "type": "basic",
        "conditions": [{
          "type": "variable_if",
          "name": "double_tap_rshift",
          "value": 2
        }],
        "from": {
          "key_code": "[% app_activators.modifiers.double_tap_rshift.apps.0.trigger_key %]"
        },
        "to": [{
          "shell_command": "[% app_activators.shell_command %] '[% app_activators.modifiers.double_tap_rshift.apps.0.app_name %]'"
        }]
      }]
    }
  ]
}
};

my $template_file = File::Spec->catfile($template_dir, 'app_activators.json.tpl');
open my $template_fh, '>', $template_file or die "Cannot create template file: $!";
print $template_fh $template_content;
close $template_fh;

# Test JSON generation order consistency
subtest 'JSON Property Order Consistency' => sub {
    plan tests => 2;

    # Generate JSON file twice
    my @first_gen = process_templates($template_dir, load_config($config_file), $output_dir);
    my $first_json = do {
        local $/;
        open my $fh, '<', $first_gen[0] or die "Cannot read first generation: $!";
        <$fh>;
    };

    # Clear output directory and regenerate files
    unlink glob "$output_dir/*";

    # Generate again
    my @second_gen = process_templates($template_dir, load_config($config_file), $output_dir);
    my $second_json = do {
        local $/;
        open my $fh, '<', $second_gen[0] or die "Cannot read second generation: $!";
        <$fh>;
    };

    # Compare raw JSON strings
    is($first_json, $second_json, 'Generated JSON strings are identical');

    # Compare parsed data structures
    is_deeply(
        decode_json($first_json),
        decode_json($second_json),
        'JSON data structures are identical'
    );
};

done_testing();