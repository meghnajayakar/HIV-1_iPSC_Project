# WGS Variant Calling

Whole-genome sequencing (WGS) variant calling, filtering, and prioritization pipeline for the extreme cell line panel. This repository contains the HPC shell scripts, R notebooks, and Jupyter notebooks used to go from raw CRAM files to a prioritized list of coding and regulatory candidate variants.

---

## 1. Set Up the Working Directory Structure

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

## 2. Repository Structure

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

## 3. Pipeline Execution Order

The pipeline runs in **three stages**. Each stage depends on the output of the previous one, so scripts must be executed in order: do not skip or reorder steps within a stage.

### Stage 1: `HPC_WGS_Scripts/` (run first, in order)

Run these shell scripts sequentially on the HPC to go from per-sample gVCFs to filtered, annotated, common-variant-removed callsets for both the coding and regulatory tracks:

1. `1persample_gvcfs.sh`: generate per-sample gVCFs
2. `2combine_gvcfs.sh`: combine per-sample gVCFs
3. `3jointgenotyping.sh`: joint genotyping across samples
4. `4variant_filtration.sh`: apply base variant filtration
5. `5.1high_variants_filtering.sh`: filter high-confidence variants
   `5.2low_variants_filtering.sh`: filter low-confidence variants
6. `6.1variant_annotation_regulatory.sh`: annotate regulatory variants
   `6.2variant_annotation_coding.sh`: annotate coding variants
7. `7.1filter_common_variants_regulatory.sh`: remove common variants (regulatory track)
   `7.2filter_common_variants_coding.sh`: remove common variants (coding track)

> Steps 5, 6, and 7 branch into paired **regulatory** and **coding** sub-tracks (`.1` = regulatory, `.2` = coding). Both sub-tracks must be run, as they feed the corresponding downstream tracks in Stages 2 and 3.

### Stage 2: `VariantFiltering_R_Scripts/` (run second, in order)

Using the outputs of `7.1filter_common_variants_regulatory.sh` and `7.2filter_common_variants_coding.sh` from Stage 1, run:

1. `0VCF_to_CSV.qmd`: convert filtered VCFs to CSV format
2. `1CodingVariantPrioritization.qmd`: initial prioritization, coding track
3. `2RegulatoryVariantPrioritization.qmd`: initial prioritization, regulatory track

### Stage 3: `VariantPrioritization_JupyterScripts/` (run third, following the required track)

Using the outputs of Stage 2, run the Jupyter notebooks for the relevant track (**coding** or **regulatory**) through to final prioritization:

**Coding track:**
1. `1.1CodingVariantPrioritization.ipynb`
2. `3.1AlphaMissense.ipynb`
3. `3.2AlphaGenome.ipynb`

**Regulatory track:**
1. `2.1MergeEnrichmentResults_Regulatory.ipynb`
2. `2.2MotifDiff.ipynb`
3. `2.3MotifDiffIntegration.ipynb`
4. `2.4FIMO_Analysis.ipynb`
5. `2.5RegulatoryVariantPrioritization.ipynb`

> Notebooks `3.1` and `3.2` (AlphaMissense / AlphaGenome) are coding-track-specific scoring steps and should be run after `1.1CodingVariantPrioritization.ipynb`. The `2.x` series notebooks are regulatory-track-specific and should be run in numerical order, culminating in `2.5RegulatoryVariantPrioritization.ipynb` for the final regulatory prioritization output.

---

## Summary of Execution Order

```
1. HPC_WGS_Scripts/            (run in numbered/lettered order: 1 → 2 → 3 → 4 → 5.1/5.2 → 6.1/6.2 → 7.1/7.2)
2. VariantFiltering_R_Scripts/ (run in numbered order: 0 → 1 → 2, using outputs of step 7.1/7.2)
3. VariantPrioritization_JupyterScripts/ (run the coding OR regulatory track, using outputs of step 2)
```
