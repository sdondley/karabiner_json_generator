# lib/KarabinerGenerator/Profiles.pm
package KarabinerGenerator::Profiles;

use strict;
use warnings;
use Exporter 'import';
use File::Path qw(make_path);
use File::Spec;
use YAML::XS qw(LoadFile);
use KarabinerGenerator::DebugUtils qw(db dbd);
use KarabinerGenerator::Config qw(get_path load_config);
use KarabinerGenerator::JSONHandler qw(read_json_file write_json_file);

use constant PROFILE_PREFIX => 'GJ';

our @EXPORT_OK = qw(
    has_profile_config
    validate_profile_config
    install_profile
    PROFILE_PREFIX
);

sub install_profile {
    my ($profile_name) = @_;
    db("\n### ENTERING install_profile() ###");
    db("Installing profile: $profile_name");

    return 0 unless defined $profile_name;

    # Read profile data
    my $triggers_dir = get_path('generated_triggers_dir');
    my $config_path = get_path('profile_config_yaml');
    my $config = eval { LoadFile($config_path) } or return 0;
    my $profile = $config->{profiles}{$profile_name} or return 0;

    # Collect rules from common and profile config
    my @rules;
    if ($profile->{common}) {
        push @rules, @{$config->{common}{rules}} if $config->{common} && $config->{common}{rules};
    }
    push @rules, @{$profile->{rules}} if $profile->{rules};

    # Get rule data from trigger files
    my @rule_data;
    for my $rule (@rules) {
        my $file = File::Spec->catfile($triggers_dir, "$rule.json");
        next unless -f $file;

        my $data = eval { read_json_file($file) };
        next if $@;
        push @rule_data, @{$data->{rules}} if $data->{rules};
    }

    # Update karabiner.json
    my $karabiner_json = get_path('karabiner_json');
    my $kb_config = eval { read_json_file($karabiner_json) };
    return 0 if $@;

    # Create or update profile
    my $full_name = PROFILE_PREFIX . "-$profile_name";
    my ($kb_profile) = grep { $_->{name} eq $full_name } @{$kb_config->{profiles}};

    unless ($kb_profile) {
        push @{$kb_config->{profiles}}, {
            name => $full_name,
            complex_modifications => { rules => [] },
            parameters => {},
            selected => JSON::false,
            simple_modifications => [],
            fn_function_keys => [],
            devices => []
        };
        $kb_profile = $kb_config->{profiles}[-1];
    }

    # Update profile rules
    $kb_profile->{complex_modifications}{rules} = \@rule_data;

    # Only set virtual_hid_keyboard if keyboard type is specified
    if (exists $profile->{keyboard}) {
        my $keyboard_type = $profile->{keyboard};
        # Validate and default to ansi if invalid
        $keyboard_type = 'ansi' unless $keyboard_type =~ /^(?:ansi|iso|jis)$/;
        $kb_profile->{virtual_hid_keyboard} = {
            keyboard_type_v2 => $keyboard_type
        };
    }

    # Save changes
    eval { write_json_file($karabiner_json, $kb_config) };
    return 0 if $@;

    return 1;
}

sub has_profile_config {
    my $config_path = get_path('profile_config_yaml');
    return -f $config_path;
}

sub validate_profile_config {
    my $generated_json_dir = get_path('generated_json_dir');
    my $full_config = load_config();

    unless ($full_config) {
        return {
            valid => 0,
            missing_files => [],
            error => 'Failed to load configuration'
        };
    }

    my $profile_config = $full_config->{profiles} || {};
    my @required_files;

    if ($profile_config->{common} && $profile_config->{common}{rules}) {
        for my $rule (@{$profile_config->{common}{rules}}) {
            push @required_files, {
                rule => $rule,
                subdir => 'triggers'
            };
        }
    }

    if ($profile_config->{profiles}) {
        foreach my $profile_name (keys %{$profile_config->{profiles}}) {
            my $profile = $profile_config->{profiles}{$profile_name};
            if (ref $profile eq 'HASH' && $profile->{rules}) {
                for my $rule (@{$profile->{rules}}) {
                    push @required_files, {
                        rule => $rule,
                        subdir => 'triggers'
                    };
                }
            }
        }
    }

    my @missing_files;
    foreach my $file_info (@required_files) {
        my $json_file = "$file_info->{rule}.json";
        my $full_path = File::Spec->catfile($generated_json_dir, $file_info->{subdir}, $json_file);
        unless (-f $full_path) {
            push @missing_files, "$file_info->{subdir}/$json_file";
        }
    }

    return {
        valid => scalar(@missing_files) == 0,
        missing_files => \@missing_files,
        error => scalar(@missing_files) ? 'Missing required JSON files' : undef
    };
}

1;