# src/util_train.pl
# Aggregates word and class statistics for the training phase.

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
my $train_dir      = $ARGV[0] or die "Usage: $0 <train_dir> <class_stats_out> <word_stats_out>\n";
my $class_out_file = $ARGV[1] or die "Usage: $0 <train_dir> <class_stats_out> <word_stats_out>\n";
my $word_out_file  = $ARGV[2] or die "Usage: $0 <train_dir> <class_stats_out> <word_stats_out>\n";

my %class_stats; 
my %word_stats;  

# Traverse the directory tree and process each file.
find({ wanted => \&process_file, no_chdir => 1 }, $train_dir);

# Output the aggregated statistics.
print_class_stats();
print_word_stats();
exit;

# Processes a single text file to update global statistics.
sub process_file {
    my $filepath = $File::Find::name;
    return unless -f $filepath && $filepath =~ /\.txt$/;

    my $class = extract_class_from_path($filepath);
    return unless defined $class;

    $class_stats{$class}{'N_c'}++;

    open my $fh, '<:encoding(UTF-8)', $filepath or die "Cannot open $filepath: $!";
    my %words_in_doc;
    
    while (my $line = <$fh>) {
        my @words = get_words_from_line($line);
        foreach my $word (@words) {
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

# Writes class-level statistics to the specified output file.
sub print_class_stats {
    open my $fh, '>', $class_out_file or die "Cannot open $class_out_file: $!";
    print $fh "class\tN_c\tT_c\n";
    foreach my $class (sort { $a cmp $b } keys %class_stats) {
        my $Nc = $class_stats{$class}{'N_c'} // 0;
        my $Tc = $class_stats{$class}{'T_c'} // 0;
        print $fh "$class\t$Nc\t$Tc\n";
    }
    close $fh;
}

# Writes word-level statistics to the specified output file.
sub print_word_stats {
    open my $fh, '>', $word_out_file or die "Cannot open $word_out_file: $!";
    print $fh "word\tclass\tT_wc\tN_wc\n";
    foreach my $word (sort keys %word_stats) {
        foreach my $class (sort { $a cmp $b } keys %{$word_stats{$word}}) {
            my $Twc = $word_stats{$word}{$class}{'T_wc'} // 0;
            my $Nwc = $word_stats{$word}{$class}{'N_wc'} // 0;
            if ($Twc > 0 || $Nwc > 0) {
                 print $fh "$word\t$class\t$Twc\t$Nwc\n";
            }
        }
    }
    close $fh;
}