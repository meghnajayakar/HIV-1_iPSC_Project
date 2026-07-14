#!/bin/bash
#SBATCH --job-name=persample_gvcf
#SBATCH --output=logs/persample_gvcf_%j.out
#SBATCH --error=logs/persample_gvcf_%j.err
#SBATCH --cpus-per-task=4
#SBATCH --time=48:00:00
#SBATCH --mem=32G

echo "Starting per-sample gVCF generation"

# specifying directories
baseDirectory="./HIV_iPSC/WGS_variantCalling_MBJ/"
resultsDirectory="$baseDirectory/gvcf"
refDirectory="./HIV_iPSC/WGS_variantCalling_MBJ/ref/human_genome_build_38"

# load gatk version 4.2.2.0
module load gatk/4.2.2.0-gcc-13.2.0-python-3.11.6

# samples (symlink names in CRAM_selected) 
samples=("sample1", "sample2", "sample3", "sample4", "sample5")

# iterate through each sample to perform variant calling
for sample in "${samples[@]}"; do
    echo "Processing sample: $sample"

    # run GATK HaplotypeCaller -> generates per-sample genomic VCFs (gVCFs)
    # -ERC GVCF is used to retain reference confidence blocks for subsequent joint genotyping
    gatk HaplotypeCaller \
            -R "$refDirectory/Homo_sapiens_assembly38.fasta" \
            -I "$baseDirectory/CRAM_selected/${sample}.cram" \
            -O "$resultsDirectory/${sample}.g.vcf.gz" \
            -ERC GVCF
done

echo "Finished per-sample gVCF generation"

