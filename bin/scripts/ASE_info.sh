#!/bin/bash

## Sahar Mozaffari
## 4.28.16
## To get genes for which PO reads/snps
##


for file in 
cut -f1-4 -d" "  withoutsaved/FlowCell1/4972/4972_lane_6_ASE_info | grep -v D7LYM | sort -k1.4,1n -k2,2n -t" " | uniq -c | grep -v indel  | grep -v some >4972_lane6_POreads


for i in `seq 1 11`;
do
    echo $i
#    echo "grep -w \"FlowCell${i}\" newqcsorted > FC${i}_mapped"
#    grep -w "FlowCell${i}" newqcsorted > FC${i}_mapped
    echo "grep -w "FlowCell${i}" 989_sorted | sort > FC${i}_mapped"
    grep -w "FlowCell${i}" 989_sorted |  sort > FC${i}_mapped  
    mkdir map_FC${i}
    echo "for file in `cat FC${i}_mapped`; do cp "$file" map_FC${i}/  ; done "

    for file in `cat FC${i}_mapped`; do cp "$file" map_FC${i}/  ; done 

    sed -n '1~6p' map_FC${i}/* > order_FC_map
    paste FC${i}_mapped order_FC_map | awk '{print $1 $2}' > test
    sed -n '2~6p' map_FC${i}/* > order_FC_map
    paste test order_FC_map | awk '{print $1, $2, $3}' > test2
    sed -n '3~6p' map_FC${i}/* > order_FC_map
    paste test2 order_FC_map | awk '{print $1, $2, $3, $4}' > test
    sed -n '4~6p' map_FC${i}/* > order_FC_map
    paste test order_FC_map | awk '{print $1, $2, $3, $4, $5}' > test2
    sed -n '5~6p' map_FC${i}/* > order_FC_map
    paste test2 order_FC_map | awk '{print $1, $2, $3, $4, $5, $6}' > test
    sed -n '6~6p' map_FC${i}/* > order_FC_map
    paste test order_FC_map | awk '{print $1, $2, $3, $4, $5, $6, $7}' > test2
    cut -f4 -d"/" test2 | sed 's/.sorted.txt/\ /g' > new_FC_${i}
    rm test
    rm test2
done    



