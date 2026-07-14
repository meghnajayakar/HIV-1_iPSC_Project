#!/bin/bash
#SBATCH --job-name=filter_common_var_coding
#SBATCH --output=logs/filter_common_var_coding_%j.out
#SBATCH --error=logs/filter_common_var_coding_%j.err
#SBATCH --cpus-per-task=2
#SBATCH --time=06:00:00
#SBATCH --mem=12G

BASE="./HIV_iPSC/WGS_variantCalling_MBJ"
CONTAINER="$BASE/software/ensembl-vep_latest.sif"

# input annotated files
HIGH_ANN="/mnt/annotations/high_annotated_coding_variants.vcf.gz"
LOW_ANN="/mnt/annotations/low_annotated_coding_variants.vcf.gz"

# output filtered files
HIGH_RARE="/mnt/annotations/high_rare_coding_biotype.vcf.gz"
LOW_RARE="/mnt/annotations/low_rare_coding_biotype.vcf.gz"

# keep variants where gnomAD genome and exome allele frequencies are les than 0.01 or NA and where biotype is protein coding or lncRNA or miRNA or snRNA

# filter HIGH variants
echo "Filtering HIGH variants..."
singularity exec -B $BASE:/mnt $CONTAINER /bin/bash -c "
  filter_vep \
    -i $HIGH_ANN \
    --format vcf \
    --filter '((gnomADg_AF < 0.01 or not gnomADg_AF) and (gnomADe_AF < 0.01 or not gnomADe_AF)) and (BIOTYPE is protein_coding or BIOTYPE matches lncRNA or BIOTYPE matches miRNA or BIOTYPE matches snRNA)' | \
  bgzip -c > $HIGH_RARE
"
echo "Completed HIGH variant filtering"

# ---

# filter LOW variants
echo "Filtering LOW variants..."
singularity exec -B $BASE:/mnt $CONTAINER /bin/bash -c "
  filter_vep \
    -i $LOW_ANN \
    --format vcf \
    --filter '((gnomADg_AF < 0.01 or not gnomADg_AF) and (gnomADe_AF < 0.01 or not gnomADe_AF)) and (BIOTYPE is protein_coding or BIOTYPE matches lncRNA or BIOTYPE matches miRNA or BIOTYPE matches snRNA)' | \
  bgzip -c > $LOW_RARE
"
echo "Completed LOW variant filtering"
echo "Filtering complete"
