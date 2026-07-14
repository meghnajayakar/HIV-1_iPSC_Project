# Using iPSC variation to define HIV-1 regulatory networks 

Whole-genome sequencing (WGS) variant calling, filtering, and prioritization pipeline for the extreme cell line panel. This repository contains the HPC shell scripts, R notebooks, and Jupyter notebooks used to go from raw CRAM files to a prioritized list of coding and regulatory candidate variants.

## Table of Contents

- [Set Up the Working Directory Structure](#set-up-the-working-directory-structure)
- [Repository Structure](#repository-structure)
- [Pipeline Execution Order](#pipeline-execution-order)
- [Stage 2: Running `VariantFiltering_R_Scripts`](#stage-2-running-variantfiltering_r_scripts)
- [Stage 3: Running `VariantPrioritization_JupyterScripts`](#stage-3-running-variantprioritization_jupyterscripts)
  - [Coding track](#coding-track)
  - [Regulatory track](#regulatory-track)
- [Summary of Workflow](#summary-of-workflow)
- [Requirements](#requirements)

---

## Set Up the Working Directory Structure

Before running any scripts, create the project directory structure on the HPC. This keeps reference files, per-sample data, joint-called VCFs, annotations, scripts, logs, and software all organized under a single project root.

(Please follow exact directory naming as described below or modify naming consistently in each script under `HPC_WGS_Scripts`)

### Directory structure

```
WGS_variantCalling_MBJ/
├── CRAM_selected/     # symlinks to the extreme cell lines
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

### Code to create the directory structure

```bash
# Set project root
PROJECT_ROOT="WGS_variantCalling_MBJ"

# Create top-level project directory
mkdir -p "${PROJECT_ROOT}"
cd "${PROJECT_ROOT}"

# Create subdirectories
mkdir -p CRAM_selected
mkdir -p ref
mkdir -p gvcf
mkdir -p vcf
mkdir -p annotations
mkdir -p scripts/logs
mkdir -p software

echo "Directory structure created under ${PROJECT_ROOT}/"
tree "${PROJECT_ROOT}"   # optional: visualize the resulting structure
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

---

## Repository Structure

This repository contains the analysis scripts, organized into three stages that must be run **sequentially**, plus a top-level README.

```
├── HPC_WGS_Scripts/
│   ├── 1persample_gvcfs.sh
│   ├── 2combine_gvcfs.sh
│   ├── 3jointgenotyping.sh
│   ├── 4variant_filtration.sh
│   ├── 5.1high_variants_filtering.sh
│   ├── 5.2low_variants_filtering.sh
│   ├── 6.1variant_annotation_regulatory.sh
│   ├── 6.2variant_annotation_coding.sh
│   ├── 7.1filter_common_variants_regulatory.sh
│   └── 7.2filter_common_variants_coding.sh
├── VariantFiltering_R_Scripts/
│   ├── 0VCF_to_CSV.qmd
│   ├── 1CodingVariantPrioritization.qmd
│   └── 2RegulatoryVariantPrioritization.qmd
├── VariantPrioritization_JupyterScripts/
│   ├── 1.1CodingVariantPrioritization.ipynb
│   ├── 2.1MergeEnrichmentResults_Regulatory.ipynb
│   ├── 2.2MotifDiff.ipynb
│   ├── 2.3MotifDiffIntegration.ipynb
│   ├── 2.4FIMO_Analysis.ipynb
│   ├── 2.5RegulatoryVariantPrioritization.ipynb
│   ├── 3.1AlphaMissense.ipynb
│   └── 3.2AlphaGenome.ipynb
└── README.md
```

---

## Pipeline Execution Order

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

Run each script from the `HPC_WGS_Scripts/` directory (or submit via your HPC scheduler, e.g., `sbatch` or `qsub`), ensuring each completes successfully before starting the next:

```bash
cd HPC_WGS_Scripts
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

---

## Stage 2: Running `VariantFiltering_R_Scripts`

Once steps **7.1** and **7.2** have completed, their results are fed into three Quarto (`.qmd`) notebooks, also run **in order**, for conversion and initial coding/regulatory variant prioritization:

| Order | Notebook | Description |
|-------|----------|--------------|
| 1 | `0VCF_to_CSV.qmd` | Converts the filtered VCF output (from 7.1/7.2) into CSV format for downstream analysis. |
| 2 | `1CodingVariantPrioritization.qmd` | Prioritizes coding variants using the output of `7.2filter_common_variants_coding.sh`. |
| 3 | `2RegulatoryVariantPrioritization.qmd` | Prioritizes regulatory variants using the output of `7.1filter_common_variants_regulatory.sh`. |

Render these in order (e.g., using Quarto):

```bash
cd VariantFiltering_R_Scripts
quarto render 0VCF_to_CSV.qmd
quarto render 1CodingVariantPrioritization.qmd
quarto render 2RegulatoryVariantPrioritization.qmd
```

---

## Stage 3: Running `VariantPrioritization_JupyterScripts`

The notebooks in this folder pick up from the outputs of Stage 2 and are split into two independent tracks: **Coding** and **Regulatory**. Run only the notebooks belonging to the track relevant to your analysis (or both, if you need both sets of results). Within a track, notebooks must be run **in numerical order**.

### Coding track

| Order | Notebook | Description |
|-------|----------|--------------|
| 1 | `1.1CodingVariantPrioritization.ipynb` | Prioritizes coding variants using the output of `1CodingVariantPrioritization.qmd`. |
| 2 | `3.1AlphaMissense.ipynb` | Scores/annotates missense variants with AlphaMissense and integrates results into the coding prioritization. |

### Regulatory track

| Order | Notebook | Description |
|-------|----------|--------------|
| 1 | `2.1MergeEnrichmentResults_Regulatory.ipynb` | Merges regulatory enrichment results from the output of `2RegulatoryVariantPrioritization.qmd`. |
| 2 | `2.2MotifDiff.ipynb` | Computes transcription factor motif differences (MotifDiff) for regulatory variants. |
| 3 | `2.3MotifDiffIntegration.ipynb` | Integrates MotifDiff results into the regulatory prioritization data. |
| 4 | `2.4FIMO_Analysis.ipynb` | Runs FIMO motif scanning/analysis on the regulatory variant set. |
| 5 | `2.5RegulatoryVariantPrioritization.ipynb` | Final regulatory variant prioritization combining enrichment, MotifDiff, and FIMO results. |
| 6 | `3.2AlphaGenome.ipynb` | Scores/annotates regulatory variants with AlphaGenome and integrates results into the final prioritization. |

Run notebooks with Jupyter, in order, for your chosen track:

```bash
cd VariantPrioritization_JupyterScripts

# Coding track
jupyter nbconvert --to notebook --execute 1.1CodingVariantPrioritization.ipynb
jupyter nbconvert --to notebook --execute 3.1AlphaMissense.ipynb

# Regulatory track
jupyter nbconvert --to notebook --execute 2.1MergeEnrichmentResults_Regulatory.ipynb
jupyter nbconvert --to notebook --execute 2.2MotifDiff.ipynb
jupyter nbconvert --to notebook --execute 2.3MotifDiffIntegration.ipynb
jupyter nbconvert --to notebook --execute 2.4FIMO_Analysis.ipynb
jupyter nbconvert --to notebook --execute 2.5RegulatoryVariantPrioritization.ipynb
jupyter nbconvert --to notebook --execute 3.2AlphaGenome.ipynb
```

---

## Requirements

- HPC cluster with a job scheduler (e.g., SLURM/PBS)
- Singularity/Apptainer (for VEP annotation image in `software/`)
- GATK (or equivalent variant calling toolkit) for gVCF generation, combination, and joint genotyping
- VEP cache/data (`vep_data`) matching the GRCh38 reference build
- [Quarto](https://quarto.org/) for rendering `.qmd` notebooks
- R and/or Python environment with packages required by the `.qmd` notebooks
- Jupyter (JupyterLab/Notebook) with Python environment required by the `.ipynb` notebooks (e.g., AlphaMissense, AlphaGenome, FIMO/MEME suite dependencies)

---

## Summary of Execution Order

```
1. HPC_WGS_Scripts/            (run in numbered/lettered order: 1 → 2 → 3 → 4 → 5.1/5.2 → 6.1/6.2 → 7.1/7.2)
2. VariantFiltering_R_Scripts/ (run in numbered order: 0 → 1 → 2, using outputs of step 7.1/7.2)
3. VariantPrioritization_JupyterScripts/ (run the coding OR regulatory track, using outputs of step 2)
```
