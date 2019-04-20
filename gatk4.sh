#!/bin/bash
current_path=`pwd`


export gatk4='/home/masum/Documents/ZAMS/v1/gatk-4.1.1.0/gatk'
export samtools='/usr/bin/samtools'
export bwa='/usr/bin/bwa'

export fastq1=$1
export fastq2=$2
export ref=$3
export threads=$4
export sample=$5
export group=1

mkdir ${current_path}/"index"

bigRef="bwtsw"
smallRef="is"
threshold=2000000000
refsize=$(wc -c < $ref)

if [ $refsize -ge $threshold ]; then
    echo `$bwa index -p index/ref -a $bigRef `
else
    echo `$bwa index -p index/ref -a $smallRef $ref`
fi

echo `$samtools faidx $ref`
echo `${gatk4} CreateSequenceDictionary -R ref.fa -O ref.dict`

echo `bwa mem -t $threads -M -R '@RG\tID:$group\tLB:$group\tPL:ILLUMINA\tSM:$sample' index/ref $fastq1 $fastq2 | samtools view -b -S -o $sample.bam`
echo `${gatk4} --java-options "-Xmx1G" SortSam -I ${current_path}/$sample.bam -O ${current_path}/$sample.sorted.bam -SO coordinate --CREATE_INDEX true`
echo `${gatk4} --java-options "-Xmx1G" MarkDuplicates -I ${current_path}/$sample.sorted.bam -O ${current_path}/$sample.dedup.bam -M ${current_path}/$sample.metrics --REMOVE_DUPLICATES true --CREATE_INDEX true`
echo `rm -rf ${current_path}/$sample.bam ${current_path}/$sample.sorted.bam ${current_path}/$sample.sorted.bai`
echo `${gatk4} --java-options "-Xmx1G" HaplotypeCaller -R $ref -I ${current_path}/$sample.dedup.bam -O ${current_path}/gatk4.raw.vcf`
