# src/test_find.pl
use strict;
use warnings;
use File::Find;

# 引数からディレクトリパスを受け取る
my $dir = $ARGV[0] or die "Usage: $0 <directory_path>\n";

# 探索する関数
sub process {
    # .txtファイルが見つかったら、そのパスを出力する
    print "$File::Find::name\n" if /\.txt$/;
}

# 探索を実行
find(\&process, $dir);

exit 0;