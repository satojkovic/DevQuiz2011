#!perl

use strict;
use warnings;

use Clone qw(clone);
use Storable qw(dclone);

my $input = shift;
open my $in, "<", $input or die "$!";

# テストケース数
my $T = <$in>;
chomp($T);

for(my $t=0; $t<$T; $t++) {

    # データ数
    my $N = <$in>;
    chomp($N);
    
    # テストケース
    my $line = <$in>;
    chomp($line);
    my @a = split(/ /, $line);
    my @a_org = @a; # reserve

    #### すべて0になるまでdivして1回のremで取り除く場合
    my $test1_cnt;
    while(1) {
        for(my $i=0; $i<$N; $i++) {
            $a[$i] = int($a[$i]/2);
        }
        $test1_cnt++;

        my $r = check(0, $N, \@a);
        if( $r == 1 ) { last; }
    }
    $test1_cnt++; # remove countの1回を足す

    #### 1回以上のremで取り除く場合
    @a = @a_org;
    my $test2_cnt;

    # テストケース中の全部の数が少なくとも1度5の倍数となるまでに行った除算処理回数
    my $cnt = 0;
    my $div_cnt = 0;
    for(my $i=0; $i<$N; $i++) {
        while(1) {
            if( ($a[$i] % 5) == 0 ) {
                last;
            }
            else {
                $a[$i] = int( $a[$i] / 2 );
                $cnt++;
            }
        }
        if( $div_cnt < $cnt ) { $div_cnt = $cnt; }
        $cnt = 0;
    }
    
    # 除算処理を任意回行った時の5の倍数である数とその個数
    @a = @a_org;
    my @num_of_five = ();
    for(my $j=0; $j<=$div_cnt; $j++) {
        my $num = 0;

        my $str;
        for(my $i=0; $i<$N; $i++) {
            if( ($a[$i] % 5) == 0 ) {
                $num++;
                if( ! defined($str) ) { $str = $i; }
                else { $str = $str . $i; }
            }
            $a[$i] = int( $a[$i] / 2 );
        }

        if( $num == 0 ) { next; }

        my $hash = {
            'index' => $str,
            'count' => $num
        };
        push(@num_of_five, $hash);
    }
    
    # 個数でソート
    my @sorted_nof = sort { $b->{'count'} <=> $a->{'count'} } @num_of_five;

    ## 除去回数のカウント

    # 5の倍数の個数がテストケースのデータ数に等しいとき→除去回数は1度
    my $min_rem_cnt = $N;
    my $rem_cnt = 0;
    foreach my $hash (@sorted_nof) {
        if( $hash->{'count'} == $N ) {
            $min_rem_cnt = 1;
            last;
        }
    }

    # 不足分を補うインデックスを探索
    if( $min_rem_cnt != 1 && $min_rem_cnt == $N ) {
        foreach my $hash (@sorted_nof) {
            $rem_cnt = 1;
            my $key = $hash->{'index'};
            
            my @part_snof = grep {$_->{'index'} ne $key} (@sorted_nof);

            my %key_hash;
            foreach my $c (split //, $key) {
                $c = $c . "";
                $key_hash{$c} = 1;
            }

            my $fill_cnt = fill_index($rem_cnt, $N, \%key_hash, \@part_snof);

            if( $fill_cnt < $min_rem_cnt ) { $min_rem_cnt = $fill_cnt; }
        }
    }

    # test2_cnt
    $test2_cnt = $div_cnt + $min_rem_cnt;

    ####### answer
    my $ans;
    if( $test1_cnt < $test2_cnt ) {
        $ans = $test1_cnt;
    }
    else {
        $ans = $test2_cnt;
    }
    print $ans . "\n";
}

close $in;

sub fill_index {
    my ($rem_cnt, $N, $key_hash_ref, $part_snof_ref) = @_;
    
    # 残りのhash配列の中から不足を最も多く補う要素を探索する
    my $max_fill_cnt = 0;
    my $max_fill_snof_index = 0;
    my $index = 0;
    foreach my $hash (@$part_snof_ref) {
        my $cnt = 0;

        foreach my $c (split //, $hash->{'index'}) {
            $c = $c . "";
            if( ! exists($key_hash_ref->{$c}) ) { $cnt++; }
        }

        # maxのカウント数とpart_snofのインデックスを保存
        if( $cnt > $max_fill_cnt ) { 
            $max_fill_cnt = $cnt; 
            $max_fill_snof_index = $index;
        }

        $index++;
    }    

    # key_hashに追加
    foreach my $h ($part_snof_ref->[$max_fill_snof_index] ) {
        foreach my $c (split //, $h->{'index'}) {
            $c = $c . "";
            $key_hash_ref->{$c} = 1;
        }
    }
    
    # 除去回数をインクリメント
    $rem_cnt++;

    # 不足がすべてそろえば戻る
    my $kc = keys %$key_hash_ref;
    if( $kc == $N ) { return $rem_cnt; }
    else {
        my @tmp = @$part_snof_ref;
        @tmp = grep {$_->{'index'} ne $part_snof_ref->[$max_fill_snof_index]->{'index'}} (@tmp);
        
        # 再帰呼び出し
        fill_index($rem_cnt, $N, $key_hash_ref, \@tmp); 
    }
}

sub check {
    my ($index, $N, $a_ref) = @_;
    
    if( ($a_ref->[$index] % 5) == 0 ) {
        if( $index != $N-1 ) { 
            check($index+1, $N, $a_ref);
        }
        elsif( $index == $N-1 ) {
            return 1;
        }
    }
    else {
        return 0;
    }
        
}
