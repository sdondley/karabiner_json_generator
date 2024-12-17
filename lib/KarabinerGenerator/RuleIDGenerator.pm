package KarabinerGenerator::RuleIDGenerator;
use strict;
use warnings;
use Exporter 'import';
use Data::Dumper;
use Digest::MD5 qw(md5_hex);
use JSON;
use Carp qw(croak);

our @EXPORT_OK = qw(
    generate_rule_id
);

# Generate a unique ID for a rule based on its JSON content
sub generate_rule_id {
    my ($json_text) = @_;

    # Parse JSON
    my $rule;
    eval {
        $rule = decode_json($json_text);
    };
    croak "Failed to parse rule JSON: $@" if $@;

    # Remove enabled flag as it shouldn't affect the ID
    delete $rule->{enabled};

    # Configure Data::Dumper for consistent output
    local $Data::Dumper::Sortkeys = 1;  # Sort hash keys
    local $Data::Dumper::Terse = 1;     # Avoid "$VAR1 = "
    local $Data::Dumper::Indent = 0;    # Remove whitespace

    # Generate hash of the normalized structure
    return md5_hex(Dumper($rule));
}

1;