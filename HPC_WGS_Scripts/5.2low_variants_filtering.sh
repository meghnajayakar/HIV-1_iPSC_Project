#!/bin/bash
#SBATCH --job-name=low_variants
#SBATCH --output=logs/low_variants_%j.out
#SBATCH --error=logs/low_variants_%j.err
#SBATCH --cpus-per-task=4
#SBATCH --time=3:00:00
#SBATCH --mem=24G

# load bcftools
module load bcftools/1.12-gcc-13.2.0-python-3.11.6

# directories
baseDirectory="./HIV_iPSC/WGS_variantCalling_MBJ/"
vcfDirectory="$baseDirectory/vcf"

# input VCF
VCF="$vcfDirectory/cohort_all.filtered.vcf.gz"

# output
OUT_LOW="$vcfDirectory/low_specific.vcf.gz"

echo "Starting LOW-specific variant search"

# filter the VCF for specific infectivity phenotype patterns across samples.
#   -f PASS     : keep only variants that passed the GATK hard filters (removes QD2, FS60, etc.)
#   -i '...'    : inline expression to match specific sample genotype (GT) array indices:
#                 - samples 1, 2 must carry the variant (heterozygous or homozygous alternate) -> low-specific samples
#                 - samples 0, 3, and 4 must be homozygous reference (0/0) -> high-specific samples

bcftools view \
-f PASS \
-i '(GT[1]="het" || GT[1]="hom") && (GT[2]="het" || GT[2]="hom") && GT[0]="0/0" && GT[3]="0/0" && GT[4]="0/0"' \
"$VCF" \
-Oz -o "$OUT_LOW"

bcftools index "$OUT_LOW"

echo "Finished LOW-specific variant search"