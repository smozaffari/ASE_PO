#!usr/bin/env/perl

use strict;
use warnings;

my %ref;
my %alt;
my %rs;

#for CRI:
#open (COD, "/group/ober-resources/users/smozaffari/POeQTL/data/ASE/testrecode.txt") || die "nope: $!";
#for Beagle2:
open (COD, "/lustre/beagle2/ober/users/smozaffari/ASE/data/testrecode.txt") || die "nope: $!";
my $snpnum = 1;
while (my $line = <COD>) {
    my @line = split " ", $line;
    my $snp = $snpnum;
    $ref{$snp} = $line[1];
    $alt{$snp} = $line[2];
    $rs{$snp} = $line[3];
    $snpnum++;
}

for (my $i=1; $i<=22; $i++) {
    my $chr = join "", "chr", $i, "_gtype";
#   for CRI
#   open (APED, "/group/ober-resources/users/smozaffari/POeQTL/data/ASE/phased_2_impute/$chr") || die "nope: $!";
#   for Beagle2
    open (APED, "/lustre/beagle2/ober/users/smozaffari/ASE/data/Impute2/genotypes/$chr")|| die "nope: $!";
    my $out = join "", "chr", $i, "_impute";
    open (IMP, ">$out") || die "nope: $!";
    open (ERR, ">>missing_impute") || die "nope: $!";
    while (my $line = <APED>) {
	my $missing =0;
	my @line = split " ", $line;
	my $length = $#line;
	my $snp = $line[0];
	my $loc = $line[1];
	print IMP ("$snp $rs{$snp} $snp $loc $ref{$snp} $alt{$snp} ");
	for (my $j=2; $j <= $length; $j+=2) {
	    my $k = $j+1;
	    if ($line[$j] eq $ref{$snp}) {
		if ( $line[$j] eq $line[$k]) {
		    print IMP "1 0 0 ";
		} else {
		    print IMP "0 1 0  ";
		}
	    } elsif ($line[$j] eq $alt{$snp}) {
		if ($line[$j] eq $line[$k]) {
		    print IMP "0 0 1 ";
		} else {
		    print IMP "0 1 0 ";
		}
	    } else {
		$missing ++;
		print IMP "1 0 0 ";
	    }
	}
	print IMP "\n";
	if ($missing > 0) {
	    print ERR ("$chr $snp $rs{$snp} $snp $loc $ref{$snp} $alt{$snp} missing: $missing\n");
	}    
    }
}   
