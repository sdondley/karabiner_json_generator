use strict;
use warnings;
use Test::Most tests => 4, 'die';
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use JSON qw(encode_json decode_json);

# Import the config module with required functions
use KarabinerGenerator::Config qw(mode get_path);

# Test module loading
use_ok('KarabinerGenerator::RuleIDGenerator', qw(generate_rule_id));

# Helper to convert Perl data to JSON - renamed to avoid conflict
sub convert_to_json {
    my ($data) = @_;
    return encode_json($data);
}

# Test identical JSON rules generate same ID
subtest 'Identical rules' => sub {
    plan tests => 3;
    
    my $rule_json1 = convert_to_json({
        description => "Test Rule",
        manipulators => [
            {
                type => "basic",
                from => { key_code => "a" },
                to => [ { key_code => "b" } ]
            }
        ]
    });
    
    my $rule_json2 = convert_to_json({
        description => "Test Rule",
        manipulators => [
            {
                type => "basic",
                from => { key_code => "a" },
                to => [ { key_code => "b" } ]
            }
        ]
    });
    
    my $id1 = generate_rule_id($rule_json1);
    my $id2 = generate_rule_id($rule_json2);
    
    ok($id1, 'Generated first ID');
    ok($id2, 'Generated second ID');
    is($id1, $id2, 'Identical rules generate same ID');
};

# Test that enabled flag doesn't affect ID
subtest 'Enabled flag ignored' => sub {
    plan tests => 2;
    
    my $rule_json1 = convert_to_json({
        description => "Test Rule",
        enabled => JSON::true,
        manipulators => [
            {
                type => "basic",
                from => { key_code => "a" },
                to => [ { key_code => "b" } ]
            }
        ]
    });
    
    my $rule_json2 = convert_to_json({
        description => "Test Rule",
        enabled => JSON::false,
        manipulators => [
            {
                type => "basic",
                from => { key_code => "a" },
                to => [ { key_code => "b" } ]
            }
        ]
    });
    
    my $id1 = generate_rule_id($rule_json1);
    my $id2 = generate_rule_id($rule_json2);
    
    ok($id1, 'Generated ID for enabled rule');
    is($id1, $id2, 'Enabled flag does not affect ID');
};

# Test real rule files from fixtures
subtest 'Real rule files' => sub {
    plan tests => 3;
    
    # Read valid complex modification file from test fixtures
    my $valid_mod_path = get_path('valid_complex_mod');
    open(my $fh1, '<', $valid_mod_path) or die "Cannot read valid complex mod: $!";
    my $mod_json = do { local $/; <$fh1> };
    close($fh1);
    
    # Generate ID for the same rule with different formatting
    my $mod_rule = decode_json($mod_json);
    my $reformatted_json = encode_json($mod_rule);
    
    my $id1 = generate_rule_id($mod_json);
    my $id2 = generate_rule_id($reformatted_json);
    
    ok($id1, 'Generated ID from file');
    is($id1, $id2, 'Different JSON formatting generates same ID');
    
    # Test malformed JSON using the malformed fixture
    throws_ok(
        sub { generate_rule_id('{"invalid": "json"') },
        qr/Failed to parse rule JSON/,
        'Invalid JSON throws error'
    );
};