#!usr/bin/env/perl

use strict;
use warnings;

my %gene;
my %rs;
my %ann;

open (ANN, "/lustre/beagle2/ober/users/smozaffari/ASE/data/all12_imputed_cgi.annovar_plink_annotations.hg19_multianno.txt") || die "nope: $!";
my $f = <ANN>;
while (my $line = <ANN>) {
    my @line = split "\t", $line;
    my $chr = $line[0];
    my $loc = $line[1];
    $rs{$chr}{$loc} = $line[14];
    $gene{$chr}{$loc} = $line[6];
    $ann{$chr}{$loc} = $line[5];
}

open (FILES, "/lustre/beagle2/ober/users/smozaffari/ASE/results/test_ASE") || die "nope: $!";
while (my $fileline = <FILES>) {
    my @findiv_lane = split "/", $fileline;
    my $name = $findiv_lane[3];
    chomp $name;
    my $outfile = "out_$name.txt";
    open (OUT, ">summarystats/$outfile") || die "nope: $!";
    open (ASE, $fileline) || die "nope: $!";
#open (ASE, "/lustre/beagle2/ober/users/smozafari/ASE/results/withoutsaved/FlowCell8/122462/122462_lane_5_ASE_info") || die "nope: $!";
#open (ASE, "test_5") || die "nope: $!";                                                                                                        
    while (my $line = <ASE>) {
	my @line = split " ", $line;
	if ($line[0] =~ m/chr/ ) {
	    my $chr = $line[0];
	    my $snp = $line[1];
	    print OUT ( join "\t", $chr, $snp, $rs{$chr}{$snp}, $gene{$chr}{$snp}, $ann{$chr}{$snp}, $line[2], $line[3], "\n");
	}
    }
    close (OUT);
    close (ASE);
}
close(FILES);
