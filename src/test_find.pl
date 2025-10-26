# src/test_find.pl
# Simple script to test File::Find functionality.
use strict;
use warnings;
use File::Find;

my $dir = $ARGV[0] or die "Usage: $0 <directory_path>\n";

# Processing subroutine for File::Find.
sub process {
    print "$File::Find::name\n" if /\.txt$/;
}

# Execute the search.
find(\&process, $dir);

exit 0;