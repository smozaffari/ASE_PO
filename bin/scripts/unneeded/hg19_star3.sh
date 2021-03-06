#!/bin/bash
# Script that will be executed on the compute nodes

. /opt/modules/default/init/bash
if [ ! $(module list -t 2>&1 | grep PrgEnv-gnu) ]; then
 module swap PrgEnv-cray PrgEnv-gnu
fi

export PATH="/lustre/beagle2/ober/users/smozaffari/miniconda2/bin:$PATH"

export $SCRIPTDIR=$1
export $INPUTDIR=$3
export $SNP_DIR=$4

module load bcftools
module load samtools/1.1

scriptName=$(basename ${0})
echo $scriptName
scriptName=${scriptName%\.sh}
echo $scriptName

timeTag=$(date "+%y_%m_%d_%H_%M_%S")                                                                                                                                                                                                                                      
export plog=$PWD/PO_${LOGNAME}_${timeTag}_star.log
echo $plog
maplog=$PWD/mapping.log
echo $maplog

echo "RUNNING $scriptName as " $(readlink -f $0 ) " on " `date`  | tee  $plog

TRIM_READ() { # trim adaptors
    read=$1
    findiv=$2
    fastq=$3
    index=$4
#    sample=$5
    echo "$fastq"
    IFS=','
    fastqs=( $fastq)
    for i in "${fastqs[@]}"; do
	ADAPTOR_SEQ="GATCGGAAGAGCACACGTCTGAACTCCAGTCAC${index}ATCTCGTATGCCGTCTTCTGCTTG"
	echo "$ADAPTOR_SEQ"
	output=$(echo "$i" | sed 's/txt.gz/trim.txt/g')
	tooshort=$(echo "$i" | sed 's/txt.gz/tooshort5.txt/g')
	echo "$output"
	echo "$index"
	echo "cutadapt -b $ADAPTOR_SEQ -m 5 --too-short-output $tooshort --format FASTQ -o $output $i"
	cutadapt -b $ADAPTOR_SEQ -m 5 --too-short-output $tooshort --format FASTQ -o $output $i
    done
    IFS=''
}


MAP_AND_SAM() {   # map files using bowtie
    read=$1
    findiv=$2
    IFS=''
    input=$3
    sample=$4
    echo "$input"
    
    echo "/lustre/beagle2/ober/users/smozaffari/STAR//STAR-2.5.2a/bin/Linux_x86_64/STAR --genomeDir /lustre/beagle2/ober/users/smozaffari/ASE/bin/ref/star/overhang/  --readFilesIn $input  --runThreadN 3 --outFileNamePrefix $read/$sample"

    /lustre/beagle2/ober/users/smozaffari/STAR/STAR-2.5.2a/bin/Linux_x86_64/STAR --genomeDir /lustre/beagle2/ober/users/smozaffari/ASE/bin/ref/star/overhang/ --readFilesIn $input --runThreadN 3 --outFileNamePrefix $read/$sample


    echo "samtools view -S -h -q 10 -b $read/${sample}Aligned.out.sam > $read/${sample}.bam"
    samtools view -S -h -q 10 -b $read/${sample}Aligned.out.sam > $read/${sample}.bam

    echo "samtools sort $read/${sample}.bam $read/${sample}.sorted"
    samtools sort $read/${sample}.bam $read/${sample}.sorted
    echo "samtools view -c -F 255 $read/${sample}.sorted.bam > $read/${sample}.sorted.txt"
    samtools view -c -F 255 $read/${sample}.sorted.bam > $read/${sample}.sorted.txt
    echo "samtools index $read/${sample}.sorted.bam"
    samtools index $read/${sample}.sorted.bam 

}

WASP() { # use WASP to remove mapping bias
    read=$1
    findiv=$2
    snp_dir=$3
    sample=$4
    lane=$5
    #first part of WASP:
    python $WASP/mapping/find_intersecting_snps.py $read/${sample}.sorted.bam  $snp_dir
    echo "python $WASP/mapping/find_intersecting_snps.py $read/${sample}.sorted.bam  $snp_dir"

    #remap files:
    echo "/lustre/beagle2/ober/users/smozaffari/STAR//STAR-2.5.2a/bin/Linux_x86_64/STAR --genomeDir /lustre/beagle2/ober/users/smozaffari/ASE/bin/ref/star/overhang/  --readFilesIn $read/${sample}.sorted.remap.fq.gz --readFilesCommand zcat --outFileNamePrefix $read/${sample}.sorted.map2"

    /lustre/beagle2/ober/users/smozaffari/STAR/STAR-2.5.2a/bin/Linux_x86_64/STAR --genomeDir /lustre/beagle2/ober/users/smozaffari/ASE/bin/ref/star/overhang/ --readFilesIn $read/${sample}.sorted.remap.fq.gz --readFilesCommand zcat --outFileNamePrefix $read/${sample}.sorted.map2

   wait

    echo "samtools view -S -h -q 10 -b $read/${sample}.sorted.map2Aligned.out.sam > $read/${sample}.sorted.remap.bam"
    samtools view -S -h -q 10 -b $read/${sample}.sorted.map2Aligned.out.sam > $read/${sample}.sorted.remap.bam

    #WASP:

    python $WASP/mapping/filter_remapped_reads.py $read/${sample}.sorted.to.remap.bam $read/${sample}.sorted.remap.bam $read/${sample}.sorted.remap.keep.bam $read/${sample}.sorted.to.remap.num.gz
    echo "python $WASP/mapping/filter_remapped_reads.py $read/${sample}.sorted.to.remap.bam $read/${sample}.sorted.remap.bam $read/${sample}.sorted.remap.keep.bam $read/${sample}.sorted.to.remap.num.gz"
    wait

    #merged bamfile:
    samtools merge $read/${sample}.keep.merged.bam $read/${sample}.sorted.keep.bam $read/${sample}.sorted.remap.keep.bam
    echo "samtools merge $read/${sample}.keep.merged.bam $read/${sample}.sorted.keep.bam $read/${sample}.sorted.remap.keep.bam"
    samtools sort $read/${sample}.keep.merged.bam $read/${sample}.keep.merged.sorted
    echo "samtools sort $read/${sample}.keep.merged.bam $read/${sample}.keep.merged.sorted"
    samtools index $read/${sample}.keep.merged.sorted.bam
    echo "samtools index $read/${sample}.keep.merged.sorted.bam"

    samtools index $read/${sample}.sorted.sort.bam
    echo "samtools index $read/${sample}.sorted.sort.bam"
    samtools view $read/${sample}.sorted.sort.bam chrX -b > $read/${sample}.chrX.bam
    echo "samtools view $read/${sample}.sorted.sort.bam chrX -b > $read/${sample}.chrX.bam"

    samtools view $read/${sample}.sorted.sort.bam chrY -b > $read/${sample}.chrY.bam
    echo "samtools view $read/${sample}.sorted.sort.bam chrY -b > $read/${sample}.chrY.bam"

    samtools view $read/${sample}.sorted.sort.bam chrM -b > $read/${sample}.chrM.bam
    echo "samtools view $read/${sample}.sorted.sort.bam chrM -b > $read/${sample}.chrM.bam"

}



ASE() {
    read=$1
    findiv=$2
    scriptdir=$3
    sample=$4
    echo "python $scriptdir/findsnps.py $read/${sample}.keep.merged.sorted.bam /lustre/beagle2/ober/users/smozaffari/ASE/data/genotypes/$findiv > $read/${sample}_ASE_info"
    python $scriptdir/findsnps.py $read/${sample}.keep.merged.sorted.bam /lustre/beagle2/ober/users/smozaffari/ASE/data/genotypes/$findiv > $read/${sample}_ASE_info
}

GENECOUNT() {
    read=$1
    sample=$2

    samtools view  $read/${sample}.keep.merged.sorted.bam |  htseq-count -s no -m intersection-nonempty -a 30 - /lustre/beagle2/ober/users/smozaffari/ASE/bin/ref/hg19/Annotation/genes.gtf > $read/${sample}_genes
#    samtools view $read/${sample}.sort.withX.bam |  htseq-count -s no -m intersection-nonempty -a 30 - /lustre/beagle2/ober/users/smozaffari/ASE/bin/ref/hg19/Annotation/genes.gtf > $read/${sample}_genes_withsex
    samtools view  $read/${sample}.keep.merged.sorted.maternal.bam |  htseq-count -s no -m intersection-nonempty -a 30 - /lustre/beagle2/ober/users/smozaffari/ASE/bin/ref/hg19/Annotation/genes.gtf > $read/${sample}_genes_maternal
    samtools view  $read/${sample}.keep.merged.sorted.paternal.bam |  htseq-count -s no -m intersection-nonempty -a 30 - /lustre/beagle2/ober/users/smozaffari/ASE/bin/ref/hg19/Annotation/genes.gtf > $read/${sample}_genes_paternal
    samtools view $read/${sample}.keep.merged.sorted.keep.bam | htseq-count -s no -m intersection-nonempty -a 30 - /lustre/beagle2/ober/users/smozaffari/ASE/bin/ref/hg19/Annotation/genes.gtf > $read/${sample}_genes_hom

}

SEXGENES() {
    read=$1
    sample=$2
    samtools index $read/${sample}.sorted.sort.bam
    echo "samtools index $read/${sample}.sorted.sort.bam"
    samtools view $read/${sample}.sorted.sort.bam chrX -b > $read/${sample}.chrX.bam
    echo "samtools view $read/${sample}.sorted.sort.bam chrX -b > $read/${sample}.chrX.bam"

    samtools view $read/${sample}.sorted.sort.bam chrY -b > $read/${sample}.chrY.bam
    echo "samtools view $read/${sample}.sorted.sort.bam chrY -b > $read/${sample}.chrY.bam"

    samtools view $read/${sample}.sorted.sort.bam chrM -b > $read/${sample}.chrM.bam
    echo "samtools view $read/${sample}.sorted.sort.bam chrM -b > $read/${sample}.chrM.bam"


    samtools merge $read/${sample}.withX.bam $read/${sample}.keep.merged.bam $read/${sample}.chrX.bam $read/${sample}.chrY.bam $read/${sample}.chrM.bam
    echo "samtools merge $read/${sample}.withX.bam $read/${sample}.keep.merged.bam $read/${sample}.chrX.bam $read/${sample}.chrY.bam $read/${sample}.chrM.bam"
    samtools sort $read/${sample}.withX.bam $read/${sample}.sort.withX
    echo "samtools sort $read/${sample}.withX.bam $read/${sample}.sort.withX"
    samtools index $read/${sample}.sort.withX.bam
    echo "samtools index $read/${sample}.sort.withX.bam"

    echo "samtools view $read/${sample}.sort.withX.bam |  htseq-count -s no -m intersection-nonempty -a 30 - /lustre/beagle2/ober/users/smozaffari/ASE/bin/ref/hg19/Annotation/genes.gtf > $read/${sample}_genes_withsex"
    samtools view $read/${sample}.sort.withX.bam |  htseq-count -s no -m intersection-nonempty -a 30 - /lustre/beagle2/ober/users/smozaffari/ASE/bin/ref/hg19/Annotation/genes.gtf > $read/${sample}_genes_withsex
}

COUNTREADS() {
    read=$1
    sample=$2

    samtools view -c -F 256 $read/${sample}.sorted.bam > $read/${sample}.sorted.txt
    echo "samtools view -c -F 256 $read/${sample}.sorted.bam > $read/${sample}.sorted.txt"
    samtools view -c -F 256 $read/${sample}.sort.withX.bam >>$read/${sample}.sorted.txt
    echo "samtools view -c -F 256 $read/${sample}.sort.withX.bam >>$read/${sample}.sorted.txt"

    samtools view -c -F 256 $read/${sample}.keep.merged.sorted.bam >>$read/${sample}.sorted.txt
    echo "samtools view -c -F 256 $read/${sample}.keep.merged.sorted.bam >>$read/${sample}.sorted.txt"
    samtools view -c -F 256 $read/${sample}.keep.merged.sorted.keep.bam >>$read/${sample}.sorted.txt
    echo "samtools view -c -F 256 $read/${sample}.keep.merged.sorted.keep.bam >>$read/${sample}.sorted.txt"
    samtools view -c -F 256 $read/${sample}.keep.merged.sorted.paternal.bam >>$read/${sample}.sorted.txt
    echo "samtools view -c -F 256 $read/${sample}.keep.merged.sorted.paternal.bam >>$read/${sample}.sorted.txt"
    samtools view -c -F 256 $read/${sample}.keep.merged.sorted.maternal.bam >>$read/${sample}.sorted.txt
    echo "samtools view -c -F 256 $read/${sample}.keep.merged.sorted.maternal.bam >>$read/${sample}.sorted.txt"
}

export -f TRIM_READ
export -f MAP_AND_SAM
export -f WASP
export -f ASE
export -f GENECOUNT


PROCESS_SHELL() {

echo $SCRIPTDIR
export FLOWCELLFINDIV=$1
echo $INPUTDIR
echo $SNP_DIR
WASP=$SCRIPTDIR/WASP
export lane=$2
export index=$3
echo "index:" $index
echo "lane:" $lane

file=${lane}.${index}.sequence.txt.gz
echo "file:" $file
ID=$(echo "$FLOWCELLFINDIV" | sed 's/\//./g')
#lane=$(echo "$file" | cut -f1 -d".")
echo "lane:" $lane
FINDIV=$(echo "$FLOWCELLFINDIV" | awk -F'/' '{print $2}')
echo $ID
echo $FINDIV

echo "SCRIPTDIR:" $SCRIPTDIR
declare -A adaptor_index
adaptor_index=( [1]="ATCACG" [2]="CGATGT" [3]="TTAGGC" [4]="TGACCA" [5]="ACAGTG" [6]="GCCAAT" [7]="CAGATC" [8]="ACTTGA" [9]="GATCAG" [10]="TAGCTT" [11]="GGCTAC" [12]="CTTGTA" [13]="AGTCAA" [14]="AGTTCC" [15]="ATGTCA" [16]="CCGTCC" [18]="GTCCGC" [1\
9]="GTGAAA" [20]="GTGGCC" [21]="GTTTCG" [22]="CGTACG" [23]="GAGTGG" [25]="ACTGAT" [27]="ATTCCT")

echo ${adaptor_index[1]}

READ=$INPUTDIR/$FLOWCELLFINDIV
echo "dir of read:" $READ
FILE=$READ/$file
echo "dir of read with file:" $FILE

SAMPLE=${FINDIV}_${lane}
LANEWASP=${lane}_WASP
echo $SAMPLE
echo $FILE
echo $SNP_DIR
echo $SCRIPTDIR
echo $lane
echo $LANEWASP

IFS='.'
array=( $file )
indexnum=${array[1]}
IFS='_'
array2=( $indexnum )
index=${array2[1]}
echo "$FINDIV $index"
IFS=''

adaptor=$(echo ${adaptor_index[$index]} )
echo $adaptor


TRIM_READ $READ $FINDIV $FILE $adaptor $SAMPLE >>$plog 2>&1 
echo "TRIM_READ $READ $FINDIV $FILE $adaptor $SAMPLE  >>$plog 2>&1"

input=$(echo "$FILE" | sed 's/txt.gz/trim.txt/g')
echo "$input"
MAP_AND_SAM $READ $FINDIV $input $SAMPLE >>$plog 2>&1
echo "MAP_AND_SAM $READ $FINDIV $input $SAMPLE  >>$plog 2>&1"

WASP $READ $FINDIV $SNP_DIR $SAMPLE $LANEWASP>>$plog 2>&1
echo "WASP $READ $FINDIV $SNP_DIR $SAMPLE $LANEWASP>>$plog 2>&1"

ASE $READ $FINDIV $SCRIPTDIR $SAMPLE >>$plog 2>&1
echo "ASE $READ $FINDIV $SCRIPTDIR $SAMPLE >>$plog 2>&1"

GENECOUNT $READ $SAMPLE >>$plog 2>&1
echo "GENECOUNT $READ $FINDIV $SCRIPTDIR $SAMPLE >>$plog 2>&1"

SEXGENES $READ  $SAMPLE  >>$plog 2>&1
echo "SEXGENES $READ  $SAMPLE >>$plog 2>&1"

COUNTREADS $READ $SAMPLE >>$plog 2>&1
echo "COUNTREADS $READ $SAMPLE >>$plog 2>&1"

}

export -f PROCESS_SHELL

echo "parallel --xapply -d \":\" -j 10 PROCESS_SHELL  ::: $2 ::: $5 ::: $6 2>&1" | tee $plog
#parallel --xapply -d ":" -j 10 PROCESS_SHELL ::: $SCRIPTDIR ::: $FLOWCELLFINDIV ::: $INPUTDIR ::: $SNPDIR ::: $FILE  2>&1
parallel --xapply -d ":" -j 10 PROCESS_SHELL  ::: $2 ::: $5 ::: $6 2>&1
