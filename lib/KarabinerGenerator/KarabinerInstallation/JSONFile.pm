# lib/KarabinerGenerator/KarabinerInstallation/JSONFile.pm
package KarabinerGenerator::KarabinerInstallation::JSONFile;

use strict;
use warnings;
use Exporter 'import';
use KarabinerGenerator::JSONHandler qw(read_json_file write_json_file validate_json);
use KarabinerGenerator::Init qw(is_test_mode db);
use KarabinerGenerator::CLI qw(run_ke_cli_cmd);
use KarabinerGenerator::ComplexModifications qw(collect_all_rules);
use KarabinerGenerator::Config qw(get_path);

our @EXPORT_OK = qw(
    validate_karabiner_json
    get_profile_names
    get_current_profile
    add_profile
    clear_profile_rules
    add_profile_rules
    update_generated_rules
    reset_karabiner_json
);

sub reset_karabiner_json {
    db("\n### ENTERING reset_karabiner_json() ###");

    my $file_path = get_path('karabiner_json');
    db("Using karabiner_json path: $file_path");

    # Create minimal valid configuration
    my $config = {
        global => {
            check_for_updates_on_startup => JSON::true,
            show_in_menu_bar => JSON::true,
            show_profile_name_in_menu_bar => JSON::false
        },
        profiles => [
            {
                name => "Default",
                complex_modifications => {
                    rules => []
                },
                devices => [],
                fn_function_keys => [],
                parameters => {
                    delay_milliseconds_before_open_device => 1000
                },
                selected => JSON::true,
                simple_modifications => []
            }
        ]
    };

    # Write the configuration
    eval {
        write_json_file($file_path, $config);
    };
    if ($@) {
        db("Error writing file: $@");
        return 0;
    }

    return 1;
}

sub validate_karabiner_json {
    my ($file_path) = @_;
    db("\n### ENTERING validate_karabiner_json() ###");
    return 0 unless $file_path;

    my $json = eval { read_json_file($file_path) };
    return 0 unless $json && validate_json($json);

    # In test mode, just validate structure
    return 1 if is_test_mode();

    # In production, use CLI validation
    my $result = run_ke_cli_cmd(['--lint-complex-modifications', $file_path]);
    return $result->{status} == 0;
}

sub get_profile_names {
    my ($file_path) = @_;
    db("\n### ENTERING get_profile_names() ###");
    return [] unless $file_path;

    if (is_test_mode()) {
        db("Test mode - reading directly from file");
        my $config = read_json_file($file_path);
        return [ map { $_->{name} } @{$config->{profiles}} ];
    }

    my $result = run_ke_cli_cmd(['--list-profile-names']);
    return [] if $result->{status} != 0;
    return [split /\n/, $result->{stdout}];
}

sub get_current_profile {
    my ($file_path) = @_;
    db("\n### ENTERING get_current_profile() ###");
    return unless $file_path;

    if (is_test_mode()) {
        db("Test mode - reading directly from file");
        my $config = read_json_file($file_path);
        for my $profile (@{$config->{profiles}}) {
            if ($profile->{selected} && $profile->{selected} == JSON::true) {
                db("Found selected profile: " . $profile->{name});
                return $profile->{name};
            }
        }
        # Return first profile if none selected
        if (@{$config->{profiles}}) {
            db("No selected profile, returning first: " . $config->{profiles}[0]{name});
            return $config->{profiles}[0]{name};
        }
        db("No profiles found");
        return;
    }

    my $result = run_ke_cli_cmd(['--get-current-profile-name']);
    return unless $result->{status} == 0;
    chomp($result->{stdout});
    return $result->{stdout};
}

sub add_profile {
    my ($config, $profile_name) = @_;
    db("\n### ENTERING add_profile() ###");
    db("Adding profile: $profile_name");

    return 0 unless $config && $profile_name;
    return 0 if grep { $_->{name} eq $profile_name } @{$config->{profiles}};

    push @{$config->{profiles}}, {
        name => $profile_name,
        complex_modifications => { rules => [] },
        parameters => {},
        selected => JSON::false,
        simple_modifications => [],
        fn_function_keys => [],
        devices => []
    };
    return 1;
}

sub clear_profile_rules {
    my ($config, $profile_name) = @_;
    return 0 unless $config && $profile_name;
    my ($profile) = grep { $_->{name} eq $profile_name } @{$config->{profiles}};
    return 0 unless $profile;

    $profile->{complex_modifications}{rules} = [];
    return 1;
}

sub add_profile_rules {
    my ($config, $profile_name, $rules) = @_;
    return 0 unless $config && $profile_name && ref($rules) eq 'ARRAY';
    my ($profile) = grep { $_->{name} eq $profile_name } @{$config->{profiles}};
    return 0 unless $profile;

    $profile->{complex_modifications} //= {};
    $profile->{complex_modifications}{rules} //= [];
    push @{$profile->{complex_modifications}{rules}}, reverse @$rules;
    return 1;
}

sub update_generated_rules {
    my ($config, $rules_dir) = @_;
    return 0 unless $config && $rules_dir && -d $rules_dir;

    my $profile_name = 'Generated JSON';
    my ($profile) = grep { $_->{name} eq $profile_name } @{$config->{profiles}};

    add_profile($config, $profile_name) unless $profile;
    clear_profile_rules($config, $profile_name);

    my $rules = collect_all_rules($rules_dir);
    return add_profile_rules($config, $profile_name, $rules);
}

1;