# src/util_classify.pl
# Converts classification data into TSV format for R processing.

use strict;
use warnings;
use utf8;
use open qw(:std :utf8);
use File::Find;
use File::Basename;

# Load the custom utility module from the current directory.
use lib dirname(__FILE__);
use TextUtil qw(get_words_from_line extract_class_from_path);

# Verify command line arguments.
my $input_dir   = $ARGV[0] or die "Usage: $0 <input_dir> <output_tsv>\n";
my $output_file = $ARGV[1] or die "Usage: $0 <input_dir> <output_tsv>\n";

open my $out_fh, '>', $output_file or die "Cannot open $output_file: $!";
# Write the header row for R data table.
print $out_fh "doc_id\ttrue_class\tword\n";

# Traverse the directory tree and process each file.
find(\&process_file, $input_dir);

close $out_fh;
exit;

# Processes a single file and outputs its content in TSV format.
sub process_file {
    my $filepath = $File::Find::name;
    return unless -f $filepath && $filepath =~ /\.txt$/;

    my $class = extract_class_from_path($filepath);
    return unless defined $class;
    
    # Use the file path as the unique document identifier.
    my $doc_id = $filepath;

    open my $in_fh, '<:encoding(UTF-8)', $filepath or die "Cannot open $filepath: $!";
    while (my $line = <$in_fh>) {
        my @words = get_words_from_line($line);
        foreach my $word (@words) {
            print $out_fh "$doc_id\t$class\t$word\n";
        }
    }
    close $in_fh;
}