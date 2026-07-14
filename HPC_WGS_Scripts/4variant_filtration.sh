#!/bin/bash
#SBATCH --job-name=variant_filtering
#SBATCH --output=logs/variant_filtering_%j.out
#SBATCH --error=logs/variant_filtering_%j.err
#SBATCH --cpus-per-task=4
#SBATCH --time=24:00:00
#SBATCH --mem=32G

echo "Starting Variant Filtering"

# load gatk
module load gatk/4.2.2.0-gcc-13.2.0-python-3.11.6

# specifying directories
baseDirectory="./HIV_iPSC/WGS_variantCalling_MBJ/"
vcfDirectory="$baseDirectory/vcf"

# apply hard filters to the raw cohort VCF using GATK standard recommendations
# this tags low-quality variants based on specific statistical thresholds (does not delete low quality variants)
gatk VariantFiltration \
  -V "$vcfDirectory"/cohort_all.raw.vcf.gz \
  --filter-expression "QD < 2.0" --filter-name QD2 \
  --filter-expression "FS > 60.0" --filter-name FS60 \
  --filter-expression "MQ < 40.0" --filter-name MQ40 \
  --filter-expression "QUAL < 30.0" --filter-name QUAL30 \
  -O "$vcfDirectory"/cohort_all.filtered.vcf.gz

echo "Finished Filtering"

# QD < 2.0 -> QualByDepth - quality by depth (variant confidence normalized by depth)
# FS > 60.0 -> FisherStrand - (phred-scaled p-value showing strand bias)
# MQ < 40.0 -> MappingQuality - (overall mapping quality of reads)
# QUAL < 30.0 -> Quality - quality score threshold 