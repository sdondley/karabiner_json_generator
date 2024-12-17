# t/kjson/author/01_inspect_profile.t
use strict;
use warnings;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../../lib";
use JSON;
use Data::Dumper;
use KarabinerGenerator::Config qw(mode get_path);

# Skip unless AUTHOR_TESTING
unless ($ENV{AUTHOR_TESTING}) {
    plan skip_all => 'Author testing. Set $ENV{AUTHOR_TESTING} to run.';
}

BEGIN {
    mode('test');
}

use KarabinerGenerator::KarabinerJsonFile qw(read_karabiner_json);

# Configure Data::Dumper for readable output
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Indent = 2;

print "\nInspecting Karabiner Profiles\n";
print "=" x 80, "\n\n";

my $karabiner_json = get_path('karabiner_json');
my $config = read_karabiner_json($karabiner_json) || {};

print "Config file: $karabiner_json\n\n";

if ($config && $config->{profiles} && ref $config->{profiles} eq 'ARRAY') {
    print "Found ", scalar(@{$config->{profiles}}), " profiles\n\n";

    foreach my $profile (@{$config->{profiles}}) {
        next unless ref $profile eq 'HASH';
        print "Profile: ", ($profile->{name} || "Unnamed"), "\n";
        print "-" x (length($profile->{name} || "Unnamed") + 9), "\n";
        
        if ($profile->{complex_modifications} && 
            ref $profile->{complex_modifications}{rules} eq 'ARRAY') {
            my $rules = $profile->{complex_modifications}{rules};
            print "Rules: ", scalar(@$rules), "\n";
            
            foreach my $rule (@$rules) {
                print "  • ", ($rule->{description} || "No description"), "\n";
                if ($rule->{manipulators} && ref $rule->{manipulators} eq 'ARRAY') {
                    foreach my $manip (@{$rule->{manipulators}}) {
                        print "    - Type: ", ($manip->{type} || "unknown"), "\n";
                        if ($manip->{from}) {
                            print "    - From: ", Dumper($manip->{from});
                        }
                        if ($manip->{to} && ref $manip->{to} eq 'ARRAY') {
                            print "    - To: ", scalar(@{$manip->{to}}), " actions\n";
                        }
                    }
                }
                print "\n";
            }
        } else {
            print "No complex modifications\n";
        }
        print "\n";
    }
} else {
    print "No profiles found or invalid config structure\n\n";
}

if ($config->{global}) {
    print "Global Settings\n";
    print "-" x 14, "\n";
    print Dumper($config->{global});
    print "\n";
}

pass('Profile inspection complete');
done_testing();