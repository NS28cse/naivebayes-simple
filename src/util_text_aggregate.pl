# src/util_text_aggregate.pl.
# Aggregates word and class statistics from a directory of text files.

use strict;
use warnings;

# Force UTF-8 for the script itself and all I/O handles.
use utf8;
use open qw(:std :utf8);

use File::Find;

# Get command line arguments.
my $train_dir      = $ARGV[0] or die "Usage: $0 <train_dir> <class_stats_out> <word_stats_out>\n";
my $class_out_file = $ARGV[1] or die "Usage: $0 <train_dir> <class_stats_out> <word_stats_out>\n";
my $word_out_file  = $ARGV[2] or die "Usage: $0 <train_dir> <class_stats_out> <word_stats_out>\n";

my %class_stats; 
my %word_stats;  

# Start finding and processing files.
find(\&process_file, $train_dir);
print_class_stats();
print_word_stats();
exit;

# Subroutine to process a single file found by File::Find.
sub process_file {
    my $filepath = $File::Find::name;
    return unless -f $filepath && $filepath =~ /\.txt$/;

    # Extract class ID from the parent directory name.
    my ($class) = ($filepath =~ m|/(\d+)/[^/]+$|);
    return unless defined $class;

    $class_stats{$class}{'N_c'}++;

    # Open with explicit UTF-8 encoding.
    open my $fh, '<:encoding(UTF-8)', $filepath or die "Cannot open $filepath: $!";
    my %words_in_doc;
    
    # Aggregate counts for T_wc (total words in class) and T_c (total words in class).
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

    # Aggregate counts for N_wc (docs containing word in class).
    foreach my $word (keys %words_in_doc) {
        $word_stats{$word}{$class}{'N_wc'}++;
    }
}

# Prints class-level statistics (N_c, T_c) to the output file.
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

# Prints word-level statistics (T_wc, N_wc) to the output file.
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