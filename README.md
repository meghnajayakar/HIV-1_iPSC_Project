# WGS Variant Calling Pipeline

This repository contains the scripts and workflow used to perform whole-genome sequencing (WGS) variant calling, annotation, and prioritization for the "extreme cell lines" dataset. The pipeline runs from raw CRAM files through joint genotyping, variant filtering, VEP annotation, and final variant prioritization.

## 1. Set Up the Working Directory

Before running any scripts, create the following directory structure. All pipeline scripts assume this layout exists relative to the project root. 
(Please follow exact directory naming as described below or moditify naming consistently in each script under HPC_WGS_Scripts)

```
WGS_variantCalling_MBJ/
├── CRAM_selected/      # symlinks to the extreme cell lines
├── ref/                # reference genome
│   ├── GRCh38.fa
│   ├── GRCh38.fa.fai
│   └── GRCh38.dict
├── gvcf/               # per-sample gVCFs
├── vcf/                # joint genotyped VCF
├── annotations/        # annotations (VEP)
├── scripts/            # scripts
│   └── logs
└── software/           # singularity-vep image + vep_data
```

Create it with the following commands:

```bash
mkdir -p WGS_variantCalling_MBJ/CRAM_selected
mkdir -p WGS_variantCalling_MBJ/ref
mkdir -p WGS_variantCalling_MBJ/gvcf
mkdir -p WGS_variantCalling_MBJ/vcf
mkdir -p WGS_variantCalling_MBJ/annotations
mkdir -p WGS_variantCalling_MBJ/scripts/logs
mkdir -p WGS_variantCalling_MBJ/software

cd WGS_variantCalling_MBJ
```

**Notes:**
- `CRAM_selected/` should contain symlinks (not copies) to the CRAM files for the selected/extreme cell lines, e.g.:
  ```bash
  ln -s /path/to/original/sample.cram CRAM_selected/sample.cram
  ln -s /path/to/original/sample.cram.crai CRAM_selected/sample.cram.crai
  ```
- `ref/` must contain the GRCh38 reference FASTA along with its `.fai` index and Picard-style `.dict` file.
- `software/` should contain the Singularity image used for VEP annotation, plus the local VEP cache/data directory (`vep_data`).
- `scripts/logs/` is where job logs (stdout/stderr) from the HPC scheduler should be written.

## 2. Repository Structure

The pipeline scripts live in `HPC_WGS_Scripts/`:

```
HPC_WGS_Scripts/
├── 1persample_gvcfs.sh
├── 2combine_gvcfs.sh
├── 3jointgenotyping.sh
├── 4variant_filtration.sh
├── 5.1high_variants_filtering.sh
├── 5.2low_variants_filtering.sh
├── 6.1variant_annotation_regulatory.sh
├── 6.2variant_annotation_coding.sh
├── 7.1filter_common_variants_regulatory.sh
└── 7.2filter_common_variants_coding.sh
```

## 3. Running the Pipeline

Scripts must be run **sequentially**, in the order listed below. Each step depends on the output of the previous one(s).

| Step | Script | Description |
|------|--------|-------------|
| 1 | `1persample_gvcfs.sh` | Generate per-sample gVCFs from CRAM files against the GRCh38 reference. Output → `gvcf/` |
| 2 | `2combine_gvcfs.sh` | Combine per-sample gVCFs into a single cohort gVCF. |
| 3 | `3jointgenotyping.sh` | Perform joint genotyping across all samples. Output → `vcf/` |
| 4 | `4variant_filtration.sh` | Apply base variant filtration (e.g., hard filters / VQSR) to the joint-genotyped VCF. |
| 5.1 | `5.1high_variants_filtering.sh` | Filter for high-confidence/high-quality variants. |
| 5.2 | `5.2low_variants_filtering.sh` | Filter for low-confidence/low-quality variants (separate branch of filtering). |
| 6.1 | `6.1variant_annotation_regulatory.sh` | Annotate regulatory variants using VEP (Singularity image + `vep_data`). Output → `annotations/` |
| 6.2 | `6.2variant_annotation_coding.sh` | Annotate coding variants using VEP. Output → `annotations/` |
| 7.1 | `7.1filter_common_variants_regulatory.sh` | Filter out common regulatory variants (e.g., by population allele frequency). |
| 7.2 | `7.2filter_common_variants_coding.sh` | Filter out common coding variants (e.g., by population allele frequency). |

Run each script from the `scripts/` directory (or submit via your HPC scheduler, e.g., `sbatch` or `qsub`), ensuring each completes successfully before starting the next:

```bash
cd scripts
./1persample_gvcfs.sh
./2combine_gvcfs.sh
./3jointgenotyping.sh
./4variant_filtration.sh
./5.1high_variants_filtering.sh
./5.2low_variants_filtering.sh
./6.1variant_annotation_regulatory.sh
./6.2variant_annotation_coding.sh
./7.1filter_common_variants_regulatory.sh
./7.2filter_common_variants_coding.sh
```

Logs for each job should be written to `scripts/logs/`.

## 4. Final Analysis Notebooks

Once steps **7.1** and **7.2** have completed, the results are fed into three final Quarto (`.qmd`) notebooks for conversion, coding variant prioritization, and regulatory variant prioritization:

| Order | Notebook | Description |
|-------|----------|--------------|
| 1 | `0VCF_to_CSV.qmd` | Converts the filtered VCF output (from 7.1/7.2) into CSV format for downstream analysis. |
| 2 | `1CodingVariantPrioritization.qmd` | Prioritizes coding variants using the output of `7.2filter_common_variants_coding.sh`. |
| 3 | `2RegulatoryVariantPrioritization.qmd` | Prioritizes regulatory variants using the output of `7.1filter_common_variants_regulatory.sh`. |

Render these in order (e.g., using Quarto):

```bash
quarto render 0VCF_to_CSV.qmd
quarto render 1CodingVariantPrioritization.qmd
quarto render 2RegulatoryVariantPrioritization.qmd
```

## 5. Summary of Workflow

```
CRAM_selected/ ──▶ 1persample_gvcfs.sh ──▶ gvcf/
                                              │
                                              ▼
                                   2combine_gvcfs.sh
                                              │
                                              ▼
                                 3jointgenotyping.sh ──▶ vcf/
                                              │
                                              ▼
                                4variant_filtration.sh
                                     │              │
                                     ▼              ▼
                    5.1high_variants_filtering.sh  5.2low_variants_filtering.sh
                                     │              │
                                     ▼              ▼
                6.1variant_annotation_regulatory.sh  6.2variant_annotation_coding.sh ──▶ annotations/
                                     │              │
                                     ▼              ▼
        7.1filter_common_variants_regulatory.sh  7.2filter_common_variants_coding.sh
                                     │              │
                                     ▼              ▼
                        0VCF_to_CSV.qmd (both branches)
                                     │
                        ┌────────────┴────────────┐
                        ▼                          ▼
        2RegulatoryVariantPrioritization.qmd   1CodingVariantPrioritization.qmd
```

## 6. Requirements

- HPC cluster with a job scheduler (e.g., SLURM/PBS)
- Singularity/Apptainer (for VEP annotation image in `software/`)
- GATK (or equivalent variant calling toolkit) for gVCF generation, combination, and joint genotyping
- VEP cache/data (`vep_data`) matching the GRCh38 reference build
- [Quarto](https://quarto.org/) for rendering `.qmd` notebooks
- R and/or Python environment with packages required by the `.qmd` notebooks

---

*For questions about specific script parameters, see the comments/headers within each script in `HPC_WGS_Scripts/`.*
