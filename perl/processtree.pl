use 5.010;
use strict;
use warnings;
use File::Basename;
use Getopt::Long;

=head1 Name

Processtree.pl

=head1 Description

Read the current processes from ps -e l and print them formatted as a process tree.

=cut

=head1 Synopsis

processtree.pl

=cut

=head1 Author

Nathan Waddell <nathan.e.waddell@gmail.com>

=cut

my $help;
my $debug;
GetOptions(
    'debug'  => \$debug,
    'help|?' => \&_usage,
);

# create a hash for holding our data
my %table = ();

# build our tree
_build_tree();

# print our tree
foreach my $parent ( sort { $a <=> $b } keys %table ) {
    _print_tree( $table{$parent} );
}

exit;

=head2 Subroutines

=head2 _usage

Prints a short usage statement.

=over

=item Input

None

=item Return

None

=back

=cut

sub _usage {
    my $name = basename($0);
    say "$name";
    say "Usage: $name [OPTIONS]";
    say "\t Options:";
    say "\t\t -d --debug" . "\t" . "Turn on output debugging";
    say "\t\t -h -? --help" . "\t" . "Show this usage message";
    exit;
}

=head2 _build_tree

Reads in a process list (ps -e l) and builds a process tree hash in %table.

=over

=item Input

None

=item Returns

None

=back

=cut

sub _build_tree {

    # our data input comes from this command
    my @array = qx/ps -e l/;
    exit "Error: No output received from command: ps -e l" unless @array;

    # get our column headers
    my @fields = split /\s+/, shift @array;

    foreach my $line (@array) {
        chomp $line;

        # get the data from the line into an array, limit by number of fields
        my @data = split /\s+/, $line, scalar(@fields);

        # create a hash for holding this line's data
        my %linedata;

        # combine our keys and values
        @linedata{@fields} = @data;

        # ease of use
        my $pid = $linedata{PID};

        # get the process name separate from its args
        my ( $name, $args ) = split /\s+/, $linedata{COMMAND}, 2;

        # store it in our line's hash
        $linedata{NAME} = $name;

        # if the PPID is 0 there's no need to search for a father, so store it.
        if ( $linedata{PPID} == 0 ) {
            $table{$pid} = \%linedata;
            next;
        }

        foreach my $proc ( sort { $a <=> $b } keys %table ) {
            my $entry = $table{$proc};
            _find_father( $entry, \%linedata );
        }

    }
}

=head2 _find_father

Checks if the process or any of its child processes are the parent pid of
the child, and stores the child in the parent's CHILD array.

=over

=item Input

Required: process hashref, child hashref

=item Returns

True if parent was found, false otherwise.

=back

=cut

sub _find_father {
    my $process = shift;
    my $child   = shift;

    return unless $process;
    return unless $child;

    my $found = 0;
    if ( $process->{PID} == $child->{PPID} ) {
        unless ( $process->{CHILD} ) {
            $process->{CHILD} = [$child];
        }
        else {
            push @{ $process->{CHILD} }, $child;
        }
        $found = 1;
    }
    elsif ( $process->{CHILD} && !$found ) {
        my @kids = @{ $process->{CHILD} };
        foreach my $kid (@kids) {
            $found = _find_father( $kid, $child ) unless $found;
        }
    }
    return $found;
}

=head2 _print_tree

Recursively prints a process tree.

=over

=item Input

Required: Hashref of the process to print

=item Return

None

=back

=cut

sub _print_tree {
    my $process = shift;
    my $indent  = shift;
    return unless $process;

    my $sep = " ";
    $sep = "    " x $indent . '\_' if $indent;

    my $line = $process->{PID} . $sep . $process->{NAME};

    $line .= "\t" . "Parent:" . $process->{PPID} if $debug;

    say $line;

    if ( $process->{CHILD} ) {
        $indent++;
        foreach my $child ( @{ $process->{CHILD} } ) {
            _print_tree( $child, $indent );
        }
    }
}
