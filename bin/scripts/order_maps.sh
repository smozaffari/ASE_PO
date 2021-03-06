#!/bin/bash
## Sahar Mozaffari
## 4.8.16
## To get number of mapped reads for RNA-seq data
## BeforeWASP, AfterWASPwithsexchromosomes, AfterWASP, Unknown, Paternal, Maternal
##
## newqcsorted generated by : from Darren's file on oberlab-tk
## awk '{print "withoutsaved",$3,$1,$1,$2".sorted.txt"}' Downloads/hutt.500ht.qc_seq_lanes.txt |  sed 's/\ /\//g' | sed 's/\/lane/_lane/g' >newqcsorted
##

for i in `seq 1 11`;
do
    echo $i
#    echo "grep -w \"FlowCell${i}\" newqcsorted > FC${i}_mapped"
#    grep -w "FlowCell${i}" newqcsorted > FC${i}_mapped
    echo "grep -w "FlowCell${i}" 989_star_overhang_v19_sorted | sort > FC${i}_mapped_v19"
    grep -w "FlowCell${i}" 989_star_overhang_v19_sorted |  sort > FC${i}_mapped_v19  
    mkdir mapv19_FC${i}
    echo "for file in `cat FC${i}_mapped_v19`; do cp "$file" mapv19_FC${i}/  ; done "

    for file in `cat FC${i}_mapped_v19`; do cp "$file" mapv19_FC${i}/  ; done 

    sed -n '1~6p' mapv19_FC${i}/* > order_FC_map
    paste FC${i}_mapped_v19 order_FC_map | awk '{print $1 $2}' > test
    sed -n '2~6p' mapv19_FC${i}/* > order_FC_map
    paste test order_FC_map | awk '{print $1, $2, $3}' > test2
    sed -n '3~6p' mapv19_FC${i}/* > order_FC_map
    paste test2 order_FC_map | awk '{print $1, $2, $3, $4}' > test
    sed -n '4~6p' mapv19_FC${i}/* > order_FC_map
    paste test order_FC_map | awk '{print $1, $2, $3, $4, $5}' > test2
    sed -n '5~6p' mapv19_FC${i}/* > order_FC_map
    paste test2 order_FC_map | awk '{print $1, $2, $3, $4, $5, $6}' > test
    sed -n '6~6p' mapv19_FC${i}/* > order_FC_map
    paste test order_FC_map | awk '{print $1, $2, $3, $4, $5, $6, $7}' > test2
    cut -f4 -d"/" test2 | sed 's/.sorted.txt/\ /g' > new_FC_${i}_v19
    rm test
    rm test2
done    



