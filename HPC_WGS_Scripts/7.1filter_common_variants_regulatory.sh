#!/bin/bash
#SBATCH --job-name=filter_common_var
#SBATCH --output=logs/filter_common_var_%j.out
#SBATCH --error=logs/filter_common_var_%j.err
#SBATCH --cpus-per-task=2
#SBATCH --time=04:00:00
#SBATCH --mem=10G

BASE="./HIV_iPSC/WGS_variantCalling_MBJ"
CONTAINER="$BASE/software/ensembl-vep_latest.sif"

# input annotated files
HIGH_ANN="/mnt/annotations/high_annotated_gnomADg.vcf.gz"
LOW_ANN="/mnt/annotations/low_annotated_gnomADg.vcf.gz"

# output filtered files
HIGH_RARE="/mnt/annotations/high_rare_regulatory.vcf.gz"
LOW_RARE="/mnt/annotations/low_rare_regulatory.vcf.gz"

# keep variants where the gnomAD genome allele frequency is less than 0.01 or NA and where a cCRE annotation exists 

# filter HIGH variants
echo "Filtering HIGH variants"
singularity exec -B $BASE:/mnt $CONTAINER /bin/bash -c "
  filter_vep \
    -i $HIGH_ANN \
    --format vcf \
    --force_overwrite \
    --filter '(gnomADg_AF < 0.01 or not gnomADg_AF) and cCRE exists' | \
  bgzip -c > $HIGH_RARE
"

echo "Completed HIGH variant filtering"

# filter LOW variants
echo "Filtering LOW variants"
singularity exec -B $BASE:/mnt $CONTAINER /bin/bash -c "
  filter_vep \
    -i $LOW_ANN \
    --format vcf \
    --force_overwrite \
    --filter '(gnomADg_AF < 0.01 or not gnomADg_AF) and cCRE exists' | \
  bgzip -c > $LOW_RARE
"

echo "Completed LOW variant filtering"
echo "Filtering complete"
