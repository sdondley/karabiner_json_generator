# ManifestTest.pm
package ManifestTest;

use strict;
use warnings;
use YAML::XS;
use File::Basename qw(dirname basename);
use Cwd qw(abs_path);
use Exporter 'import';
use File::Temp qw(tempfile);
use Term::ReadKey;
use File::Find;
use File::Spec;
use Carp qw(croak);
use KarabinerGenerator::DebugUtils qw(db);

our @EXPORT_OK = qw(run_manifest_test);

# Module state
our $PROJECT_ROOT;
BEGIN {
    my $manifest_path = abs_path(__FILE__);
    $PROJECT_ROOT = dirname($manifest_path);
}

# Track our temp file
my ($RUN_FH, $RUN_FILE);

sub _get_manifest_path {
    return "$PROJECT_ROOT/Manifest.yaml";
}

sub _find_all_modules {
    my $lib_dir = File::Spec->catdir($PROJECT_ROOT, '..', '..');
    db("Scanning lib directory: $lib_dir");
    my @pm_files;

    find({
        wanted => sub {
            # Skip hidden files and directories at any level
            my $file = $File::Find::name;
            my @path_parts = File::Spec->splitdir($file);
            return if grep { /^\./ } @path_parts;

            return unless -f && /\.pm$/;
            my $rel_path = File::Spec->abs2rel($file, $lib_dir);
            my @parts = split(/\//, $rel_path);
            $parts[-1] =~ s/\.pm$//;
            my $module = join('::', @parts);
            db("Found module: $module");
            push @pm_files, $module;
        },
        no_chdir => 1
    }, $lib_dir);

    my @sorted = sort @pm_files;
    db("Found " . scalar(@sorted) . " total modules");
    return @sorted;
}

sub _extract_subs_from_module {
    my ($module_name) = @_;
    db("Extracting subs from module: $module_name");

    # Get the module file path
    my $module_path = $module_name;
    $module_path =~ s/::/\//g;
    $module_path .= ".pm";

    # Find the module in @INC
    my $file_path;
    for my $inc (@INC) {
        my $try = "$inc/$module_path";
        if (-f $try) {
            $file_path = $try;
            db("Found module at: $file_path");
            last;
        }
    }

    return unless $file_path;  # Return undef if module not found

    # Read the file content
    open my $fh, '<', $file_path or return;  # Return undef if can't open
    my $content = do { local $/; <$fh> };
    close $fh;

    # Extract sub names using regex
    my @subs;
    while ($content =~ /^\s*sub\s+(\w+)\s*\{/mg) {
        push @subs, $1;
    }

    my @sorted = sort @subs;
    db("Found " . scalar(@sorted) . " subs: " . join(", ", @sorted));
    return @sorted;
}

sub _load_manifest {
    db("Loading manifest");
    my $manifest_path = _get_manifest_path();
    db("Checking manifest exists at: $manifest_path");

    db("Reading manifest file");
    my $manifest = YAML::XS::LoadFile($manifest_path);
    db("Manifest loaded with " . scalar(keys %$manifest) . " modules");
    return $manifest;
}

sub _compare_subs {
    my ($module, $manifest_subs, $actual_subs) = @_;
    db("Comparing subs for module: $module");

    return {
        module_deleted => 1,
        manifest_subs => $manifest_subs
    } unless defined $actual_subs;

    # Clean up arrays and ensure consistent sorting
    my @clean_manifest = sort map { s/^\s+|\s+$//g; $_ } @$manifest_subs;
    my @clean_actual = sort map { s/^\s+|\s+$//g; $_ } @$actual_subs;

    my %manifest_set = map { $_ => 1 } @clean_manifest;
    my %actual_set = map { $_ => 1 } @clean_actual;

    my @added;
    for my $sub (@clean_actual) {
        push @added, $sub unless exists $manifest_set{$sub};
    }

    my @removed;
    for my $sub (@clean_manifest) {
        push @removed, $sub unless exists $actual_set{$sub};
    }

    if (@added) {
        db("Added subs for $module: " . join(", ", @added));
    }
    if (@removed) {
        db("Removed subs for $module: " . join(", ", @removed));
    }

    return {
        added => \@added,
        removed => \@removed,
        has_changes => (@added || @removed) ? 1 : 0,
        current_subs => \@clean_actual
    };
}

sub _check_manifest {
    my $manifest = _load_manifest();
    my %changes;
    my @new_modules;
    my @deleted_modules;

    # Get all current modules
    db("Starting module scan");
    my @current_modules = _find_all_modules();
    my %current_modules = map { $_ => 1 } @current_modules;
    my %manifest_modules = map { $_ => 1 } keys %$manifest;

    # Check for new modules
    for my $module (@current_modules) {
        unless (exists $manifest_modules{$module}) {
            db("Found new module: $module");
            push @new_modules, $module;
        }
    }

    # Check for deleted modules and changes
    for my $module (sort keys %$manifest) {
        my @manifest_subs = sort @{$manifest->{$module}};
        if (!exists $current_modules{$module}) {
            db("Found deleted module: $module");
            push @deleted_modules, $module;
            next;
        }

        my @actual_subs = _extract_subs_from_module($module);
        my $comparison = _compare_subs($module, \@manifest_subs, \@actual_subs);

        if ($comparison->{has_changes}) {
            $changes{$module} = $comparison;
            db("Found changes in module: $module");
        }
    }

    # Display changes, new modules, and deleted modules
    if (%changes || @new_modules || @deleted_modules) {
        print STDERR "\nManifest discrepancies found:\n\n";

        # Display deleted modules first
        if (@deleted_modules) {
            print STDERR "Deleted modules:\n";
            for my $module (sort @deleted_modules) {
                print STDERR "$module:\n";
                print STDERR "  - $_\n" for sort @{$manifest->{$module}};
            }
            print STDERR "\n";
        }

        # Display new modules
        if (@new_modules) {
            print STDERR "New modules found:\n";
            for my $module (sort @new_modules) {
                my @subs = _extract_subs_from_module($module);
                print STDERR "$module:\n";
                print STDERR "  + $_\n" for sort @subs;
                $changes{$module} = {
                    added => \@subs,
                    removed => [],
                    has_changes => 1,
                    current_subs => \@subs
                };
            }
            print STDERR "\n";
        }

        # Display changes to existing modules
        for my $module (sort keys %changes) {
            next if grep { $_ eq $module } @new_modules; # Skip new modules
            my $module_changes = $changes{$module};

            if (@{$module_changes->{added}}) {
                print STDERR "$module - New subroutines:\n";
                print STDERR "  + $_\n" for sort @{$module_changes->{added}};
            }

            if (@{$module_changes->{removed}}) {
                print STDERR "$module - Removed subroutines:\n";
                print STDERR "  - $_\n" for sort @{$module_changes->{removed}};
            }
            print STDERR "\n";
        }

        # Single prompt for all changes
        print STDERR "\nDo you want to update the manifest with these changes? [Y/n] ";
        STDERR->autoflush(1);
        ReadMode('cbreak');
        my $key = ReadKey(0);
        ReadMode('normal');
        print STDERR "$key\n";

        if (lc($key) ne 'n') {  # Default to yes for any key except 'n'
            _update_manifest(\%changes, \@deleted_modules);
        } else {
            print STDERR "\nNo changes made to manifest.\n";
        }
    }

    return 1;
}

sub _update_manifest {
    my ($changes, $deleted_modules) = @_;
    db("Updating manifest");
    my $manifest = _load_manifest();

    # Remove deleted modules
    for my $module (@$deleted_modules) {
        db("Removing deleted module from manifest: $module");
        delete $manifest->{$module};
    }

    # Update manifest with current state for both existing and new modules
    for my $module (keys %$changes) {
        db("Updating module in manifest: $module");
        $manifest->{$module} = [sort @{$changes->{$module}->{current_subs}}];
    }

    # Write updated manifest
    my $manifest_path = _get_manifest_path();
    db("Writing manifest to: $manifest_path");
    YAML::XS::DumpFile($manifest_path, $manifest);

    print STDERR "\nManifest updated successfully.\n";
}

sub run_manifest_test {
    db("Starting manifest test");

    # If we have a run file from a previous run, check it
    if ($RUN_FILE && -f $RUN_FILE) {
        db("Found previous run file: $RUN_FILE");
        return 1;
    }

    # Load and check manifest
    _check_manifest();

    # Create temp file to mark successful run
    db("Creating temp file to mark completion");
    ($RUN_FH, $RUN_FILE) = tempfile(
        'manifest_run_XXXX',
        DIR => "$PROJECT_ROOT/../../../.test_output",
        UNLINK => 1
    );
    print $RUN_FH "1\n";
    close $RUN_FH;
    db("Created temp file: $RUN_FILE");

    return 1;
}

1;