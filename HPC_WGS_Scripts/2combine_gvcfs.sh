#!/bin/bash
#SBATCH --job-name=combine_gvcfs
#SBATCH --output=logs/combine_gvcfs_%j.out
#SBATCH --error=logs/combine_gvcfs_%j.err
#SBATCH --cpus-per-task=4
#SBATCH --time=24:00:00
#SBATCH --mem=32G

echo "Starting CombineGVCFs"

# load the GATK module
module load gatk/4.2.2.0-gcc-13.2.0-python-3.11.6

# specifying directories
baseDirectory="./HIV_iPSC/WGS_variantCalling_MBJ/"
gvcfDirectory="$baseDirectory/gvcf"
resultsDirectory="$baseDirectory/vcf"
refDirectory="./HIV_iPSC/WGS_variantCalling_MBJ/ref/human_genome_build_38"

# combine individual sample gVCFs into a single cohort gVCF
# this consolidation optimizes performance before running joint genotyping 
gatk CombineGVCFs \
    -R "$refDirectory/Homo_sapiens_assembly38.fasta" \
    $(for f in "$gvcfDirectory"/*.g.vcf.gz; do echo "-V $f"; done) \
    -O "$resultsDirectory/cohort_all.g.vcf.gz"

echo "Finished CombineGVCFs"
