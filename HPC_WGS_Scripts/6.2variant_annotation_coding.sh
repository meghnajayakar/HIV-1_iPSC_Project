#!/bin/bash
#SBATCH --job-name=vep_coding
#SBATCH --output=logs/vep_coding_%j.out
#SBATCH --error=logs/vep_coding_%j.err
#SBATCH --cpus-per-task=4
#SBATCH --time=48:00:00
#SBATCH --mem=32G

echo "Starting VEP annotation with Polyphen, SIFT"

BASE="./HIV_iPSC/WGS_variantCalling_MBJ"

CONTAINER="$BASE/software/ensembl-vep_latest.sif"
CACHE="$BASE/software/vep_data"

REF="/mnt/ref/human_genome_build_38/Homo_sapiens_assembly38.fasta"

HIGH="/mnt/vcf/high_specific.vcf.gz"
LOW="/mnt/vcf/low_specific.vcf.gz"

HIGH_OUT="/mnt/annotations/high_annotated_coding_variants.vcf.gz"
LOW_OUT="/mnt/annotations/low_annotated_coding_variants.vcf.gz"

# # run Ensembl Variant Effect Predictor (VEP) using a Singularity container.
# -B binds the host directory $BASE to /mnt inside the container so VEP can access local files.

# for both infectivity classes, specific to coding variants:
# annotate with gene symbol, canonical transcript, HGVS notation, PolyPhen-2 scores, SIFT scores, protein, exon numbers, regulatory feature, gnomAD exome and genome allele frequencies, custom cCRE BED from ENCODE
# the final output is compressed 

singularity exec \
  -B $BASE:/mnt \
  $CONTAINER \
  vep \
    -i $HIGH \
    -o $HIGH_OUT \
    --cache \
    --dir_cache /mnt/software/vep_data \
    --fasta $REF \
    --assembly GRCh38 \
    --offline \
    --vcf \
    --symbol \
    --canonical \
    --hgvs \
    --protein \
    --numbers \
    --sift b \
    --polyphen b \
    --variant_class \
    --regulatory \
    --af_gnomad \
    --af_gnomadg \
    --custom file=/mnt/annotations/GRCh38-cCREs.bed.gz,short_name=cCRE,format=bed,type=overlap,fields=4%6 \
    --compress_output bgzip \
    --fork 4 \
    --force_overwrite

echo "Finished HIGH variants"

singularity exec \
  -B $BASE:/mnt \
  $CONTAINER \
  vep \
    -i $LOW \
    -o $LOW_OUT \
    --cache \
    --dir_cache /mnt/software/vep_data \
    --fasta $REF \
    --assembly GRCh38 \
    --offline \
    --vcf \
    --symbol \
    --canonical \
    --hgvs \
    --protein \
    --numbers \
    --sift b \
    --polyphen b \
    --variant_class \
    --regulatory \
    --af_gnomad \
    --af_gnomadg \
    --custom file=/mnt/annotations/GRCh38-cCREs.bed.gz,short_name=cCRE,format=bed,type=overlap,fields=4%6 \
    --compress_output bgzip \
    --fork 4 \
    --force_overwrite

echo "Finished LOW variants"
echo "VEP annotation completed"
