#!/bin/bash

# Sahar Mozaffari
# 8/23/2016
# updated: 6/15/2017

# PURPOSE: verify bam id on everyone, this runs one person, one flowcell/lane at a time (depending on input file for bamid1.sh)
# INPUT: from bamid1.sh
# USAGE : aprun -n 1 -N 1 -d 32  -b /lustre/beagle2/ober/users/smozaffari/ASE/bin/verifybamid/bamid3.sh $FINDIV $FC $LANE $JOBSPERNODE $COUNT

# load plink
# load verifyBamID / to download latest version: from John:
### Clone from GitHub using SSH (can alternatively use HTTPS)
### git clone git@github.com:statgen/verifyBamID.git
### cd verifyBamID
### make cloneLib
### make
### The executable binary is in the subdirectory bin/.


#these four lines are for beagle
. /opt/modules/default/init/bash
if [ ! $(module list -t 2>&1 | grep PrgEnv-gnu) ]; then
 module swap PrgEnv-cray PrgEnv-gnu
fi

module load python/2.7.6-vanilla
#loaded to run plink-1.99

rm -r /tmp/sm
ls -l /tmp/
rm /tmp/*
# mv to tmp because we are going to run against everyone, so better storage of file than to read it again and again
#dd bs=8M if=/lustre/beagle2/ober/users/smozaffari/ASE/results/genotypecheck2/qc_to_vcf_kao_170615.vcf.gz of=/tmp/test.vcf.gz
dd bs=8M if=/lustre/beagle2/ober/users/smozaffari/qc_to_vcf_kao_170621_0.1.vcf.gz of=/tmp/test.vcf.gz                                                                                                              

F=$(echo $2 | tr ':' '\n' | sort -nu)
echo $F


# this is for running one person against their own:
# grab information from file 989_flowcell_lane_3 which looks like regular input file:
# FlowCell8.122462.lane_5
# FlowCell8.122462.lane_4
# FlowCell8.108861.lane_1


scriptName=$(basename ${0})
echo $scriptName
scriptName=${scriptName%\.sh}
echo $scriptName
scriptDir=$(readlink -f "$(dirname "$0")")
echo $scriptDir

timeTag=$(date "+%y_%m_%d_%H_%M_%S")

plog=$PWD/verifybamid_${LOGNAME}_${timeTag}.log
echo $plog


GENOTYPES() {
    FINDIV=$1

    echo "HUTTERITES "$FINDIV | tee $plog
#    if [ ! -e "${FINDIV}.vcf" ]
#    then
#	echo "HUTTERITES "$FINDIV > $FINDIV.txt

#copied plink files from tarbell to Beagle - give location of these files
#	echo "plink-1.9 --bfile /lustre/beagle2/ober/users/smozaffari/Hutterites/PRIMAL/data-sets/qc/qc --keep-allele-order --keep $FINDIV.txt --recode vcf --out $FINDIV" | tee $plog
#	plink-1.9 --bfile /lustre/beagle2/ober/users/smozaffari/Hutterites/PRIMAL/data-sets/qc/qc --keep-allele-order --keep ${FINDIV}.txt --recode vcf --out $FINDIV
#    fi 
    FC=$2
    LANE=$3

#path to verifyBamID

# To run one person against themselves:
#    echo "/lustre/beagle2/ober/users/smozaffari/verifyBamID/bin/verifyBamID --vcf /tmp/test.vcf.gz --bam /lustre/beagle2/ober/users/smozaffari/ASE/results/star_overhang_v19/$FC/$FINDIV/${FINDIV}_${LANE}.sorted.bam  --ignoreRG --smID HUTTERITES_${FINDIV} --self --verbose --out ${FINDIV}_${FC}_${LANE}_allself" | tee $plog
#    /lustre/beagle2/ober/users/smozaffari/verifyBamID/bin/verifyBamID --vcf /tmp/test.vcf.gz --bam /lustre/beagle2/ober/users/smozaffari/ASE/results/star_overhang_v19/$FC/$FINDIV/${FINDIV}_${LANE}.sorted.bam  --ignoreRG --smID HUTTERITES_${FINDIV} --self --verbose --out ${FINDIV}_${FC}_${LANE}_allself

# To run one person against everybody:
    echo "/lustre/beagle2/ober/users/smozaffari/verifyBamID/bin/verifyBamID --vcf /tmp/test.vcf.gz --bam /lustre/beagle2/ober/users/smozaffari/ASE/results/star_overhang_v19/$FC/$FINDIV/${FINDIV}_${LANE}.sorted.bam  --ignoreRG  --best --verbose --out ${FINDIV}_${FC}_${LANE}_allbest" | tee $plog
    /lustre/beagle2/ober/users/smozaffari/verifyBamID/bin/verifyBamID --vcf /tmp/test.vcf.gz --bam /lustre/beagle2/ober/users/smozaffari/ASE/results/star_overhang_v19/$FC/$FINDIV/${FINDIV}_${LANE}.sorted.bam  --ignoreRG  --best --verbose --out ${FINDIV}_${FC}_${LANE}_allbest

}


export -f GENOTYPES

#GENOTYPES $1 $2 $3 >>$plog 2>&1
#echo "GENOTYPES $1 $2 $3 >>$plog 2>&1"

echo "parallel --xapply -d \":\" -j $4 GENOTYPES ::: $1 ::: $2 ::: $3 2>&1"
parallel --xapply -d : -j $4 GENOTYPES  ::: $1 ::: $2 ::: $3  2>&1

rm /tmp/test.vcf

#for item in $F; do
#    rm /dev/shm/${item}_${NUM}.vcf
#done


