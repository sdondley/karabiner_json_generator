package KarabinerGenerator::ComplexModifications;
use strict;
use warnings;
use JSON;
use Carp qw(croak);
use File::Find;
use File::Spec;
use Exporter 'import';

use KarabinerGenerator::Validator qw(validate_files);

# Add to @EXPORT_OK
our @EXPORT_OK = qw(
    list_available_rules
    read_rule_file
    get_rule_metadata
    collect_all_rules
    validate_rule_file
);

# New function to validate rules
sub validate_rule_file {
    my ($file_path) = @_;
    return validate_files($file_path);
}

# List all available complex modification rules in the given directory
sub list_available_rules {
    my ($dir) = @_;
    croak "Directory not specified" unless $dir;
    croak "Directory does not exist: $dir" unless -d $dir;

    my @rules;
    find(
        {
            wanted => sub {
                return unless -f && /\.json$/;

                # Try to read and parse the file
                eval {
                    my $rule = read_rule_file($File::Find::name);
                    push @rules, {
                        file => $File::Find::name,
                        title => $rule->{title},
                        rules => scalar(@{$rule->{rules} || []})
                    };
                };
                warn "Error processing $File::Find::name: $@" if $@;
            },
            no_chdir => 1
        },
        $dir
    );

    return \@rules;
}

# Read and parse a single rule file
sub read_rule_file {
    my ($file_path) = @_;
    croak "File not specified" unless $file_path;
    croak "File does not exist: $file_path" unless -f $file_path;

    open(my $fh, '<', $file_path) or croak "Cannot read file: $!";
    my $content = do { local $/; <$fh> };
    close($fh);

    my $rule;
    eval {
        $rule = decode_json($content);
    };
    croak "Failed to parse JSON in $file_path: $@" if $@;

    # Basic structure validation
    croak "Invalid rule file structure in $file_path"
        unless ref($rule) eq 'HASH' &&
               exists $rule->{title} &&
               exists $rule->{rules} &&
               ref($rule->{rules}) eq 'ARRAY';

    return $rule;
}

# Extract metadata from a rule definition
sub get_rule_metadata {
    my ($rule) = @_;
    croak "Rule not specified" unless $rule && ref($rule) eq 'HASH';

    my $metadata = {
        title => $rule->{title},
        rules => []
    };

    foreach my $subrule (@{$rule->{rules} || []}) {
        push @{$metadata->{rules}}, {
            description => $subrule->{description},
            manipulator_count => scalar(@{$subrule->{manipulators} || []})
        };
    }

    return $metadata;
}

sub collect_all_rules {
    my ($dir) = @_;
    croak "Directory not specified" unless $dir;
    croak "Directory does not exist: $dir" unless -d $dir;

    my @all_rules;

    # Get list of all rule files
    my $available_rules = list_available_rules($dir);

    # Process each file
    foreach my $rule_file (@$available_rules) {
        # Read the full rule file
        my $rule_data = read_rule_file($rule_file->{file});

        # Add each rule from this file to our collection
        push @all_rules, @{$rule_data->{rules}};
    }

    return \@all_rules;
}

1;