# src/util_text_aggregate.pl.
# Aggregates word and class statistics from a directory of text files.
# Input: A directory specified by a command-line argument.
# Output: Writes TSV-formatted statistics to two specified output files.

use strict;
use warnings;

# --- Start of encoding fix ---
# Force UTF-8 encoding for the script itself and for all I/O handles.
# This is the most robust way to handle Unicode characters.
use utf8;
use open qw(:std :utf8);
# --- End of encoding fix ---

use File::Find;

# Get arguments from the command line.
my $train_dir      = $ARGV[0] or die "Usage: $0 <train_dir> <class_stats_out> <word_stats_out>\n";
my $class_out_file = $ARGV[1] or die "Usage: $0 <train_dir> <class_stats_out> <word_stats_out>\n";
my $word_out_file  = $ARGV[2] or die "Usage: $0 <train_dir> <class_stats_out> <word_stats_out>\n";


# Global Variables.
my %class_stats; 
my %word_stats;  

# Main Logic.
find(\&process_file, $train_dir);
print_class_stats();
print_word_stats();
exit;

# Subroutine to process a single file.
sub process_file {
    my $filepath = $File::Find::name;
    return unless -f $filepath && $filepath =~ /\.txt$/;

    # The regex for extracting class is now more robust against path variations.
    my ($class) = ($filepath =~ m|/(\d+)/[^/]+$|);
    return unless defined $class;

    $class_stats{$class}{'N_c'}++;

    # open with explicit UTF-8 encoding.
    open my $fh, '<:encoding(UTF-8)', $filepath or die "Cannot open $filepath: $!";
    my %words_in_doc;
    while (my $line = <$fh>) {
        chomp $line;
        my @words = split /[ 　]+/, $line;
        foreach my $word (@words) {
            next if $word eq '';
            $word_stats{$word}{$class}{'T_wc'}++;
            $class_stats{$class}{'T_c'}++;
            $words_in_doc{$word} = 1;
        }
    }
    close $fh;

    foreach my $word (keys %words_in_doc) {
        $word_stats{$word}{$class}{'N_wc'}++;
    }
}

# Prints class-level statistics to a file using tabs as separators.
sub print_class_stats {
    open my $fh, '>', $class_out_file or die "Cannot open $class_out_file: $!";
    print $fh "class\tN_c\tT_c\n";
    foreach my $class (sort { $a <=> $b } keys %class_stats) {
        my $Nc = $class_stats{$class}{'N_c'} // 0;
        my $Tc = $class_stats{$class}{'T_c'} // 0;
        print $fh "$class\t$Nc\t$Tc\n";
    }
    close $fh;
}

# Prints word-level statistics to a file using tabs as separators.
sub print_word_stats {
    open my $fh, '>', $word_out_file or die "Cannot open $word_out_file: $!";
    print $fh "word\tclass\tT_wc\tN_wc\n";
    foreach my $word (sort keys %word_stats) {
        foreach my $class (sort { $a <=> $b } keys %{$word_stats{$word}}) {
            my $Twc = $word_stats{$word}{$class}{'T_wc'} // 0;
            my $Nwc = $word_stats{$word}{$class}{'N_wc'} // 0;
            if ($Twc > 0 || $Nwc > 0) {
                 print $fh "$word\t$class\t$Twc\t$Nwc\n";
            }
        }
    }
    close $fh;
}