#!/bin/bash
#SBATCH --job-name=high_variants
#SBATCH --output=logs/high_variants_%j.out
#SBATCH --error=logs/high_variants_%j.err
#SBATCH --cpus-per-task=4
#SBATCH --time=24:00:00
#SBATCH --mem=24G

# load bcftools
module load bcftools/1.12-gcc-13.2.0-python-3.11.6

# directories
baseDirectory="./HIV_iPSC/WGS_variantCalling_MBJ/"
vcfDirectory="$baseDirectory/vcf"

# input VCF
VCF="$vcfDirectory/cohort_all.filtered.vcf.gz"

# output
OUT_HIGH="$vcfDirectory/high_specific.vcf.gz"

echo "Starting HIGH-specific variant search"

# filter the VCF for specific infectivity phenotype patterns across samples.
#   -f PASS     : keep only variants that passed the GATK hard filters (removes QD2, FS60, etc.)
#   -i '...'    : inline expression to match specific sample genotype (GT) array indices:
#                 - samples 0, 3, and 4 must carry the variant (heterozygous or homozygous alternate) -> high-specific samples
#                 - samples 1 and 2 must be homozygous reference (0/0) -> low-specific samples

bcftools view \
-f PASS \
-i '(GT[0]="het" || GT[0]="hom") && (GT[3]="het" || GT[3]="hom") && (GT[4]="het" || GT[4]="hom") && GT[1]="0/0" && GT[2]="0/0"' \
"$VCF" \
-Oz -o "$OUT_HIGH"

bcftools index "$OUT_HIGH"

echo "Finished HIGH-specific variant search"