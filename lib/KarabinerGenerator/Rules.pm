package KarabinerGenerator::Rules;
use strict;
use warnings;
use Exporter 'import';
use JSON;
use Carp qw(croak);
use KarabinerGenerator::RuleIDGenerator qw(generate_rule_id);

our @EXPORT_OK = qw(
    create_ordered_rules
    find_rule_by_id
);

# Create ordered array of rules with IDs
sub create_ordered_rules {
    my ($rules) = @_;
    croak "Rules array not provided" unless ref($rules) eq 'ARRAY';

    my $ordered_rules = [];
    for my $rule (@$rules) {
        my $rule_json = encode_json($rule);
        my $id = generate_rule_id($rule_json);
        push @$ordered_rules, { $id => $rule_json };
    }

    return $ordered_rules;
}

# Find a rule by its ID in ordered rules array
sub find_rule_by_id {
    my ($ordered_rules, $target_id) = @_;
    croak "Ordered rules array not provided" unless ref($ordered_rules) eq 'ARRAY';
    croak "Target ID not provided" unless $target_id;

    my ($rule) = grep { exists $_->{$target_id} } @$ordered_rules;
    return unless $rule;

    return decode_json($rule->{$target_id});
}

1;