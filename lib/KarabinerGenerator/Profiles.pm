package KarabinerGenerator::Profiles;

use strict;
use warnings;
use Exporter 'import';
use YAML::XS qw(DumpFile LoadFile);
use File::Spec;
use File::Basename;
use File::Path qw(make_path);
use JSON;
use KarabinerGenerator::Config qw(get_path);

use constant PROFILE_PREFIX => 'GJ';

# Add to @EXPORT_OK
our @EXPORT_OK = qw(
    PROFILE_PREFIX
    has_profile_config
    generate_config
    validate_profile_config
    bundle_profile
    get_profile_names
    install_bundled_profile
    ensure_profile_environment
);

sub has_profile_config {
    my $config_path = get_path('profile_config_yaml');
    return -f $config_path;
}

sub ensure_profile_environment {
    my $dirs = {
        templates_dir => get_path('templates_dir'),
        generated_json_dir => get_path('generated_json_dir'),
        generated_profiles_dir => get_path('generated_profiles_dir'),
        complex_mods_dir => get_path('complex_mods_dir')
    };

    # Create all required directories
    for my $dir_key (keys %$dirs) {
        my $dir = $dirs->{$dir_key};
        make_path($dir) unless -d $dir;
    }

    # Generate profile config if it doesn't exist
    unless (has_profile_config()) {
        generate_config();
    }

    # Create basic template if templates directory is empty
    my $template_dir = $dirs->{templates_dir};
    my @templates = glob(File::Spec->catfile($template_dir, "*.json.tpl"));
    unless (@templates) {
        my $basic_template = File::Spec->catfile($template_dir, "ctrl-esc.json.tpl");
        open my $fh, '>', $basic_template or die "Cannot create template: $!";
        print $fh qq{
{
    "title": "Control/Escape Key",
    "rules": [
        {
            "description": "Control/Escape",
            "manipulators": [
                {
                    "type": "basic",
                    "from": { "key_code": "escape" },
                    "to": [{ "key_code": "control" }]
                }
            ]
        }
    ]
}
};
        close $fh;
    }

    # Generate basic rule file if json directory is empty
    my $json_dir = $dirs->{generated_json_dir};
    my @rules = glob(File::Spec->catfile($json_dir, "*.json"));
    unless (@rules) {
        my $basic_rule = File::Spec->catfile($json_dir, "ctrl-esc.json");
        open my $fh, '>', $basic_rule or die "Cannot create rule: $!";
        print $fh qq{
{
    "title": "Control/Escape Key",
    "rules": [
        {
            "description": "Control/Escape",
            "manipulators": [
                {
                    "type": "basic",
                    "from": { "key_code": "escape" },
                    "to": [{ "key_code": "control" }]
                }
            ]
        }
    ]
}
};
        close $fh;
    }

    return 1;
}

sub generate_config {
    my $config_path = get_path('profile_config_yaml');

    # Define default configuration
    my $config = {
        common => {
            rules => ['ctrl-esc']
        },
        profiles => {
            Default => {
                title => 'Default',
                common => \1  # YAML::XS boolean true
            }
        }
    };

    eval {
        DumpFile($config_path, $config);
    };

    if ($@) {
        warn "Failed to generate profile config: $@";
        return 0;
    }

    return -f $config_path;
}

sub validate_profile_config {
    my $config_path = get_path('profile_config_yaml');
    my $generated_json_dir = get_path('generated_json_dir');

    # Check if config file exists
    unless (-f $config_path) {
        return {
            valid => 0,
            missing_files => [],
            error => 'Profile config file does not exist'
        };
    }

    # Load config file
    my $config;
    eval {
        $config = LoadFile($config_path);
    };
    if ($@) {
        return {
            valid => 0,
            missing_files => [],
            error => "Failed to parse config file: $@"
        };
    }

    # Collect all rule files that should exist
    my @required_files;

    # Add common rules
    if ($config->{common} && $config->{common}{rules}) {
        push @required_files, @{$config->{common}{rules}};
    }

    # Add profile-specific rules
    if ($config->{profiles}) {
        foreach my $profile (values %{$config->{profiles}}) {
            next unless ref $profile eq 'HASH' && $profile->{rules};
            push @required_files, @{$profile->{rules}};
        }
    }

    # Check for missing files
    my @missing_files;
    foreach my $rule (@required_files) {
        my $json_file = "$rule.json";
        my $full_path = File::Spec->catfile($generated_json_dir, $json_file);
        push @missing_files, $json_file unless -f $full_path;
    }

    return {
        valid => scalar(@missing_files) == 0,
        missing_files => \@missing_files,
        error => scalar(@missing_files) ? 'Missing required JSON files' : undef
    };
}

sub bundle_profile {
    my ($profile_name) = @_;
    return 0 unless defined $profile_name;

    my $profiles_dir = get_path('generated_profiles_dir');
    my $json_dir = get_path('generated_json_dir');
    my $config_path = get_path('profile_config_yaml');

    # Ensure profiles directory exists
    make_path($profiles_dir) unless -d $profiles_dir;

    # Load and validate profile config
    my $config = eval { LoadFile($config_path) } or return 0;
    my $profile = $config->{profiles}{$profile_name} or return 0;

    # Collect rules to bundle
    my @rules;

    # Add common rules if profile uses them
    if ($profile->{common}) {
        push @rules, @{$config->{common}{rules}} if $config->{common} && $config->{common}{rules};
    }

    # Add profile-specific rules
    push @rules, @{$profile->{rules}} if $profile->{rules};

    # Read and combine all rule files
    my @rule_data;
    for my $rule (@rules) {
        my $file = File::Spec->catfile($json_dir, "$rule.json");
        next unless -f $file;

        open my $fh, '<', $file or next;
        my $content = do { local $/; <$fh> };
        close $fh;

        my $data = eval { decode_json($content) } or next;
        push @rule_data, @{$data->{rules}} if $data->{rules};
    }

    # Create bundled profile
    my $bundled = {
        title => $profile->{title} || $profile_name,
        rules => \@rule_data
    };

    # Write bundled file
    my $output_file = File::Spec->catfile($profiles_dir, PROFILE_PREFIX . "-$profile_name.json");
    open my $out_fh, '>', $output_file or return 0;
    print $out_fh encode_json($bundled);
    close $out_fh;

    return 1;
}

sub get_profile_names {
    my $config_path = get_path('profile_config_yaml');
    return () unless -f $config_path;

    my $config = eval { LoadFile($config_path) } or return ();
    return () unless $config && $config->{profiles};

    return keys %{$config->{profiles}};
}

sub install_bundled_profile {
    my ($profile_name) = @_;
    return 0 unless defined $profile_name;

    my $profiles_dir = get_path('generated_profiles_dir');
    my $complex_mods_dir = get_path('complex_mods_dir');
    my $bundle_file = File::Spec->catfile($profiles_dir, PROFILE_PREFIX . "-$profile_name.json");

    # Check if bundle exists
    unless (-f $bundle_file) {
        warn "Bundle file does not exist for profile: $profile_name" unless $ENV{HARNESS_ACTIVE};
        return 0;
    }

    # Install the bundle
    my $dest_file = File::Spec->catfile($complex_mods_dir, PROFILE_PREFIX . "-$profile_name.json");
    eval {
        make_path($complex_mods_dir) unless -d $complex_mods_dir;
        File::Copy::copy($bundle_file, $dest_file) or die $!;
    };
    if ($@) {
        warn "Failed to install profile $profile_name: $@" unless $ENV{HARNESS_ACTIVE};
        return 0;
    }

    return -f $dest_file;
}

1;