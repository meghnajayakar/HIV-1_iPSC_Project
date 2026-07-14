#!/bin/bash
#SBATCH --job-name=joint_genotyping
#SBATCH --output=logs/joint_genotyping_%j.out
#SBATCH --error=logs/joint_genotyping_%j.err
#SBATCH --cpus-per-task=4
#SBATCH --time=45:00:00
#SBATCH --mem=32G

echo "Starting Joint Genotyping"

# load the gatk module
module load gatk/4.2.2.0-gcc-13.2.0-python-3.11.6

# specifying directories
baseDirectory="./HIV_iPSC/WGS_variantCalling_MBJ/"
resultsDirectory="$baseDirectory/vcf"
refDirectory="./HIV_iPSC/WGS_variantCalling_MBJ/ref/human_genome_build_38"

# perform the final joint-genotyping step on the combined cohort gVCF
# thtis applies a joint error model across all samples, allowing the algorithm to distinguish true variants from sequencing artifacts 
# out is a standard, multi-sample VCF 
gatk GenotypeGVCFs \
    -R "$refDirectory/Homo_sapiens_assembly38.fasta" \
    -V "$resultsDirectory/cohort_all.g.vcf.gz" \
    -O "$resultsDirectory/cohort_all.raw.vcf.gz"

echo "Finished Joint Genotyping"
