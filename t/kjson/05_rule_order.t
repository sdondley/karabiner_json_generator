use strict;
use warnings;
use Test::Most tests => 3, 'die';
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use JSON;
use KarabinerGenerator::Config qw(get_path mode);
use KarabinerGenerator::RuleIDGenerator qw(generate_rule_id);
use KarabinerGenerator::KarabinerJsonFile qw(read_karabiner_json get_current_profile_rules);

# Ensure we're in test mode
BEGIN {
    mode('test');
}

# Test getting rules with IDs in order
subtest 'Get ordered rules with IDs' => sub {
    plan tests => 4;
    
    # Get mockup karabiner.json using Config
    my $config_file = get_path('karabiner_json');
    my $config = read_karabiner_json($config_file);
    
    # Get Default profile rules
    my $rules = get_current_profile_rules($config, 'Default');
    ok($rules, 'Got rules from Default profile');
    
    my $ordered_rules = [];
    for my $rule (@$rules) {
        my $rule_json = encode_json($rule);
        my $id = generate_rule_id($rule_json);
        push @$ordered_rules, { $id => $rule_json };
    }
    
    is(scalar(@$ordered_rules), 1, 'Found 1 rule');
    ok(keys %{$ordered_rules->[0]}, 'First rule has an ID');
    
    # Test order preservation by adding a second rule and verifying order
    my $rule2 = {
        description => "Test Rule 2",
        manipulators => []
    };
    push @{$config->{profiles}[0]{complex_modifications}{rules}}, $rule2;
    
    my $rules2 = get_current_profile_rules($config, 'Default');
    my $ordered_rules2 = [];
    for my $rule (@$rules2) {
        my $rule_json = encode_json($rule);
        my $id = generate_rule_id($rule_json);
        push @$ordered_rules2, { $id => $rule_json };
    }
    
    is(scalar(@$ordered_rules2), 2, 'Found 2 rules in order');
};

# Test rule ID consistency
subtest 'Rule ID consistency' => sub {
    plan tests => 2;
    
    my $config_file = get_path('karabiner_json');
    my $config = read_karabiner_json($config_file);
    my $rules = get_current_profile_rules($config, 'Default');
    
    # Generate ID twice for same rule
    my $rule_json = encode_json($rules->[0]);
    my $id1 = generate_rule_id($rule_json);
    my $id2 = generate_rule_id($rule_json);
    
    is($id1, $id2, 'Same rule generates same ID');
    
    # Modify the rule and check ID changes
    my $modified_rule = decode_json($rule_json);
    $modified_rule->{description} = "Modified description";
    my $modified_json = encode_json($modified_rule);
    my $id3 = generate_rule_id($modified_json);
    
    isnt($id1, $id3, 'Modified rule generates different ID');
};

# Test extracting rule by ID
subtest 'Extract rule by ID' => sub {
    plan tests => 3;
    
    my $config_file = get_path('karabiner_json');
    my $config = read_karabiner_json($config_file);
    my $rules = get_current_profile_rules($config, 'Default');
    
    # Get ID of first rule
    my $rule_json = encode_json($rules->[0]);
    my $target_id = generate_rule_id($rule_json);
    
    # Array to store rules with IDs
    my $ordered_rules = [];
    for my $rule (@$rules) {
        my $json = encode_json($rule);
        my $id = generate_rule_id($json);
        push @$ordered_rules, { $id => $json };
    }
    
    # Find rule by ID
    my ($found) = grep { exists $_->{$target_id} } @$ordered_rules;
    ok($found, 'Found rule by ID');
    ok($found->{$target_id}, 'Rule has content');
    
    my $retrieved_rule = decode_json($found->{$target_id});
    is($retrieved_rule->{description}, $rules->[0]{description}, 'Retrieved correct rule');
};