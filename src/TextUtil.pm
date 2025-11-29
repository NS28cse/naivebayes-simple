# src/TextUtil.pm
package TextUtil;

use strict;
use warnings;
use utf8;
use Exporter 'import';

# Export functions for external use.
our @EXPORT_OK = qw(get_words_from_line extract_class_from_path);

# Splits a text line into words based on half-width or full-width spaces.
sub get_words_from_line {
    my ($line) = @_;
    chomp $line;
    my @words = split /[ 　]+/, $line;
    return grep { $_ ne '' } @words;
}

# Extracts the class name from the file path assuming a specific directory structure.
sub extract_class_from_path {
    my ($filepath) = @_;
    # Matches the pattern .../CLASS_NAME/filename.txt.
    my ($class) = ($filepath =~ m|/([^/]+)/[^/]+$|);
    return $class;
}

# Perl modules must return a true value.
1;