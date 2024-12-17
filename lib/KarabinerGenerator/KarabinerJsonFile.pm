package KarabinerGenerator::KarabinerJsonFile;
use strict;
use warnings;
use JSON;
use Carp qw(croak);
use File::Copy;
use Exporter 'import';
use KarabinerGenerator::CLI qw(run_ke_cli_cmd);
use KarabinerGenerator::ComplexModifications qw(collect_all_rules);
use KarabinerGenerator::Config qw(get_path);

our @EXPORT_OK = qw(
    read_karabiner_json
    write_karabiner_json
    get_profile_names
    get_current_profile_rules
    lint_karabiner_json
    add_profile
    clear_profile_rules
    add_profile_rules
    update_generated_rules
);

# Remove get_config_file_path since we'll use Config.pm's get_path

# Read and parse karabiner.json file
sub read_karabiner_json {
    my ($file_path) = @_;
    $file_path ||= get_path('karabiner_json');

    unless (-f $file_path) {
        croak "Cannot read karabiner.json: No such file or directory";
    }

    open(my $fh, '<', $file_path) or croak "Cannot read karabiner.json: $!";
    my $json_text = do { local $/; <$fh> };
    close($fh);

    my $config;
    eval {
        $config = decode_json($json_text);
    };
    if ($@) {
        croak "Failed to parse karabiner.json: $@";
    }

    # Basic structure check before validation
    unless (ref($config) eq 'HASH' && exists $config->{profiles} &&
            ref($config->{profiles}) eq 'ARRAY') {
        croak "Invalid karabiner.json structure";
    }

    # Validate using CLI
    my $result = lint_karabiner_json($file_path);
    if ($result->{status} == 2) {
        croak "Failed to run karabiner_cli: " . $result->{stderr};
    }
    if ($result->{status} != 0) {
        croak "Invalid karabiner.json: " . ($result->{stderr} || "validation failed");
    }

    return $config;
}

# Create backup before making changes
sub _backup_file {
    my ($file_path) = @_;
    return 1 unless -f $file_path;  # Nothing to backup

    my $backup_path = "${file_path}~";
    unlink $backup_path if -f $backup_path;  # Remove existing backup

    copy($file_path, $backup_path)
        or croak "Failed to create backup: $!";
    return 1;
}

# Restore from backup if changes fail
sub _restore_from_backup {
    my ($file_path) = @_;
    my $backup_path = "${file_path}~";
    return 0 unless -f $backup_path;

    unlink $file_path if -f $file_path;  # Remove failed file
    copy($backup_path, $file_path)
        or croak "Failed to restore from backup: $!";
    unlink $backup_path;  # Clean up backup after successful restore
    return 1;
}

sub _write_temp_file {
    my ($config, $file_path) = @_;
    my $temp_path = "$file_path.tmp";

    open(my $fh, '>', $temp_path)
        or croak "Cannot write temporary file: $!";

    # Create a JSON object and configure it to pretty print
    my $json = JSON->new->pretty;
    print $fh $json->encode($config);

    close($fh);

    return $temp_path;
}

# Write config to karabiner.json
sub write_karabiner_json {
    my ($config, $file_path) = @_;
    $file_path ||= get_path('karabiner_json');

    # [Rest of the function remains the same...]
    # Basic structure check before attempting to write
    unless (ref($config) eq 'HASH' && exists $config->{profiles} &&
            ref($config->{profiles}) eq 'ARRAY') {
        warn "Invalid config structure";
        return 0;
    }

    # Validate enabled values
    unless (_validate_enabled_values($config)) {
        warn "Invalid 'enabled' value found - must be JSON boolean";
        return 0;
    }

    # Create backup of current state if file exists
    if (-f $file_path) {
        _backup_file($file_path);
    }

    # Write to temp file first
    my $temp_file;
    eval {
        $temp_file = _write_temp_file($config, $file_path);
    };
    if ($@) {
        warn "Failed to write config: $@";
        _restore_from_backup($file_path) if -f "${file_path}~";
        return 0;
    }

    # Validate the temp file using CLI
    my $result = lint_karabiner_json($temp_file);

    # Handle CLI execution failure
    if ($result->{status} == 2) {
        unlink $temp_file;
        warn "Failed to run karabiner_cli: " . $result->{stderr};
        _restore_from_backup($file_path) if -f "${file_path}~";
        return 0;
    }

    # Handle validation failure
    if ($result->{status} != 0) {
        unlink $temp_file;
        warn "Validation failed for written config";
        warn $result->{stderr} if $result->{stderr};
        _restore_from_backup($file_path) if -f "${file_path}~";
        return 0;
    }

    # If validation passed, move temp file to final location
    rename($temp_file, $file_path)
        or do {
            my $err = $!;
            unlink $temp_file;
            _restore_from_backup($file_path) if -f "${file_path}~";
            croak "Failed to move temp file to final location: $err";
        };

    return 1;
}

# Get list of profile names
sub get_profile_names {
    my ($config) = @_;
    return [] unless ref($config) eq 'HASH' &&
                     exists $config->{profiles} &&
                     ref($config->{profiles}) eq 'ARRAY';
    return [map { $_->{name} } @{$config->{profiles}}];
}

# Get rules for a specific profile
sub get_current_profile_rules {
    my ($config, $profile_name) = @_;
    return unless ref($config) eq 'HASH' &&
                  exists $config->{profiles} &&
                  ref($config->{profiles}) eq 'ARRAY';
    my ($profile) = grep { $_->{name} eq $profile_name } @{$config->{profiles}};
    return unless $profile;
    return $profile->{complex_modifications}{rules} || [];
}

# Lint karabiner.json using the Karabiner CLI
sub lint_karabiner_json {
    my ($file_path) = @_;
    $file_path ||= get_path('karabiner_json');
    return run_ke_cli_cmd(['--lint-complex-modifications', $file_path]);
}

sub add_profile {
    my ($config, $profile_name) = @_;

    # Input validation
    croak "Configuration not provided" unless $config;
    croak "Profile name not provided" unless defined $profile_name && length $profile_name;

    # Check if profile already exists
    my $profile_names = get_profile_names($config);
    if (grep { $_ eq $profile_name } @$profile_names) {
        return 0;  # Profile already exists
    }

    # Create new profile with basic structure
    my $new_profile = {
        name => $profile_name,
        complex_modifications => {
            rules => []
        },
        parameters => {},
        selected => JSON::false,  # New profiles are not selected by default
        simple_modifications => [],
        fn_function_keys => [],
        devices => []
    };

    # Add new profile to config
    push @{$config->{profiles}}, $new_profile;

    return 1;  # Success
}

sub _validate_enabled_values {
    my ($config) = @_;

    # Helper to check if a value is a proper JSON boolean
    my $is_json_boolean = sub {
        my $val = shift;
        return 1 if !defined $val;  # undefined is ok
        return 1 if ref($val) eq 'JSON::PP::Boolean';
        return 1 if ref($val) eq 'JSON::XS::Boolean';
        return 0;
    };

    # Recursively check all rules in all profiles
    foreach my $profile (@{$config->{profiles}}) {
        next unless ref($profile) eq 'HASH';
        next unless exists $profile->{complex_modifications};
        next unless ref($profile->{complex_modifications}) eq 'HASH';
        next unless exists $profile->{complex_modifications}{rules};
        next unless ref($profile->{complex_modifications}{rules}) eq 'ARRAY';

        foreach my $rule (@{$profile->{complex_modifications}{rules}}) {
            next unless ref($rule) eq 'HASH';
            if (exists $rule->{enabled}) {
                return 0 unless $is_json_boolean->($rule->{enabled});
            }
        }
    }

    return 1;
}

# Clear all rules from a profile
sub clear_profile_rules {
    my ($config, $profile_name) = @_;
    return 0 unless ref($config) eq 'HASH' &&
                    exists $config->{profiles} &&
                    ref($config->{profiles}) eq 'ARRAY';

    my ($profile) = grep { $_->{name} eq $profile_name } @{$config->{profiles}};
    return 0 unless $profile;

    $profile->{complex_modifications}{rules} = [];
    return 1;
}

# Add rules to a profile
sub add_profile_rules {
    my ($config, $profile_name, $rules) = @_;
    return 0 unless ref($config) eq 'HASH' &&
                    exists $config->{profiles} &&
                    ref($config->{profiles}) eq 'ARRAY' &&
                    ref($rules) eq 'ARRAY';

    my ($profile) = grep { $_->{name} eq $profile_name } @{$config->{profiles}};
    return 0 unless $profile;

    # Create complex_modifications structure if it doesn't exist
    $profile->{complex_modifications} //= {};
    $profile->{complex_modifications}{rules} //= [];

    # we reverse the rules array to put triggers before complex modifiers
    push @{$profile->{complex_modifications}{rules}}, reverse @$rules;
    return 1;
}

sub update_generated_rules {
    my ($config, $rules_dir) = @_;
    $rules_dir ||= get_path('generated_json_dir');

    # Validate inputs
    return 0 unless ref($config) eq 'HASH' &&
                    exists $config->{profiles} &&
                    ref($config->{profiles}) eq 'ARRAY';
    return 0 unless -d $rules_dir;

    # Find or create Generated Json profile
    my $profile_name = 'Generated JSON';
    my ($profile) = grep { $_->{name} eq $profile_name } @{$config->{profiles}};

    unless ($profile) {
        # Profile doesn't exist, create it
        add_profile($config, $profile_name) or return 0;
        ($profile) = grep { $_->{name} eq $profile_name } @{$config->{profiles}};
    }

    # Clear existing rules
    clear_profile_rules($config, $profile_name) or return 0;

    # Collect and add new rules
    my $rules = eval { collect_all_rules($rules_dir) };
    return 0 if $@;  # Handle any errors from collect_all_rules

    # Add the collected rules
    add_profile_rules($config, $profile_name, $rules) or return 0;

    return 1;
}

1;