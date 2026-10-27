
# CBBBioc

This package experimentally defines a Bioconductor interface to
Genentech’s
[CompBioBench](https://github.com/genentech/compbiobench-runner).
CompBioBench is a framework for evaluating agentic solutions to
computational biology questions.

`CBBBioc` includes a snapshot of the question set (`v1qs`) available
around October 2026. The package includes tooling to

- locate in cloud storage the input files each question needs
  (`cbb_url()`),
- stages per-question agent workspaces (`cbb_setup_workspace()`) in the
  same `workspace/`
- set up the `prompt.md` needed by
  [`compbiobench-runner`](https://github.com/genentech/compbiobench-runner).

See the package vignette for a worked example.

## Installation

``` r
# install.packages("remotes")
remotes::install_github("vjcitn/CBBBioc")
```

## Question catalog

`v1qs` currently holds 100 questions across these domains:

| Domain              | Freq | File types used             |
|:--------------------|-----:|:----------------------------|
| Epigenomics         |   20 | bigWig, csv, fasta, gz, tar |
| Genomics            |   20 | bam, fa, fna, gz            |
| Machine Learning    |    7 | pdf, tsv                    |
| Population Genetics |   12 | gz                          |
| Single-cell         |   21 | bam, gz, h5ad, rds, sizes   |
| Spatial             |    2 | gz                          |
| Structure           |    1 | pdb                         |
| Transcriptomics     |   17 | bam, fq, gz, tsv, txt       |

One example question per domain, wrapped (not truncated) to a fixed
width so it reads without horizontal scrolling in any viewer:

**Epigenomics**

    Consider chr11:124,738,681-124,738,772 (hg38).
    What is the likely purpose of this region? Choose
    only one. A. Active enhancer, Liver B. Active
    enhancer, Brain frontal lobe C. Active enhancer,
    ESC D. Active transcription, ubiquitous E. TSS
    poised or flanking, ubiquitous F. Polycomb
    repression, ubiquitous. Respond with a single
    letter.

**Genomics**

    Convert all of the following to Ensembl gene IDs.
    Provide the ID without the Ensembl version (e.g.,
    ENSGXXXXXXXXXXXX not ENSGXXXXXXXXXXXX.XX).
    Respond with semi-colon separated values, no
    spaces. Inputs: 1. NM_001276266.2 2. TERB2 3.
    ENST00000267814 4. chr15:45167214-45187966 (hg38)
    5. GeneID:9153 6. NP_922946.1 7. MIM:617658 8.
    BEN domain containing 5, transcript variant 6.

**Machine Learning**

    Run the DNA language model here:
    https://huggingface.co/kuleshov-group/caduceus-ph_seqlen-131k_d_model-256_n_layer-16
    on the 1000 bp long DNA sequence at hg38
    chr12:7792299-7793299. Specifically, mask each
    base one at a time, keeping all others unmasked,
    and compute the per position base 2 entropy of
    the predictions. Return the substring
    corresponding to the longest run with <0.5
    entropy.

**Population Genetics**

    Identify the PubMed ID of the study from which
    this summary statistics in
    reverse.search.gwas.q1.tsv.gz are derived. Print
    only the PMID, e.g. 31510655.

**Single-cell**

    differential.composition.q1.1.mtx.gz and
    differential.composition.q1.2.mtx.gz contain raw
    scRNA counts matrices derived from retinal
    samples of two individuals (one per file, each
    column is a unique barcode that passes QC).
    differential.composition.q1.genes.txt.gz is the
    list of common genes. One of the cell types is
    severely depleted in one of the two individuals.
    What is this cell type? Return only the name of
    the depleted cell type from this list: astrocyte,
    microglial cell, RPE cell, cone cell, rod cell,
    horizontal cell, bipolar cell, RGC, T cells,
    macrophage, Schwann cell, Pericyte, B cell,
    fibroblast, endothelial cell, muller glia cell.

**Spatial**

    You are given a set of single cell transcriptomic
    data and Visium spatial transcriptomic data
    (spatial.sim.tar.gz). The single cell counts
    matrix is found at spatial_q_sc_counts.csv, and
    accompanying cell type metadata is found at
    spatial_q_sc_metadata.csv. Spatial count data is
    found at spatial_q_matrix.mtx.gz, gene counts are
    found at spatial_q_features.tsv.gz, and are found
    at spot barcodes spatial_q_barcodes.tsv.gz.
    Finally scale factors are found at
    spatial_q_scalefactors_json.json, high and low
    resolution tissue images are found at
    spatial_q_tissue_hires_image.png and
    patial_q_tissue_hires_image.png respectively, and
    tissue positions are found at
    spatial_q_tissue_positions.csv. The spot-based
    data is comprised entirely of cell types found in
    the single cell data. Can you tell me what cell
    type or cell types, if any, are biased towards
    being in closer spatial proximity to spots
    containing Tumor_Core? If none, please return
    "None". Please list these separated by commas in
    alphabetical order. Expected answer format:
    Endothelial,Macrophage.

**Structure**

    Consider the PDB protein in the file
    protein.shape.q1.pdb. Which of the following
    uppercase letters does it resemble most closely:
    B, D, F, H, J, L, N, P, R, T, V, X, Z? Consider
    all possible projections and pick the best fit.

**Transcriptomics**

    I have a bulk human RNA-seq fastq file
    cryptic.exon.q1.fq.gz. There is exactly one
    highly expressed coding gene that has a cryptic
    exon in it formed by two novel junctions. Report
    the HGNC gene symbol (uppercase) for that gene.

73 of the 100 questions have one or more associated input files,
retrievable via `cbb_url()` and stageable with `cbb_setup_workspace()`.

### Browse the full catalog

**[Browse all questions (interactive
table)](https://vjcitn.github.io/CBBBioc/articles/question-catalog.html)**

*(the site at <https://vjcitn.github.io/CBBBioc/> is built with
[`pkgdown`](https://pkgdown.r-lib.org/) from this README, the vignettes,
and the function reference; regenerate it with
`pkgdown::build_site()`.)*

A plain-text preview of the first few questions, for quick browsing
here:

| question_id | domain | question_style | question |
|:---|:---|:---|:---|
| ensembl-grab-q1 | Genomics | Retrieval | `Convert all of the following to Ensembl gene IDs. Provide the ID without the Ensembl ve...` |
| bam-infer-read-length-q1 | Genomics | Metadata Recovery | `For the given BAM file mt.sorted.bam, infer if it's paired or single ended reads and th...` |
| differential-composition-q1 | Single-cell | Synthetic/Augmented Data | `differential.composition.q1.1.mtx.gz and differential.composition.q1.2.mtx.gz contain r...` |
| genomic-state-q1 | Epigenomics | Routine Analysis | `Consider chr11:124,738,681-124,738,772 (hg38). What is the likely purpose of this regio...` |
| cryptic-exon-q1 | Transcriptomics | Synthetic/Augmented Data | `I have a bulk human RNA-seq fastq file cryptic.exon.q1.fq.gz. There is exactly one high...` |
| read-paper-download-file-parse-q1 | Epigenomics | Retrieval | `Take a look at the pdf here: https://www.biorxiv.org/content/10.1101/2023.10.04.560808v...` |
| huggingface-entropy-q1 | Machine Learning | Tooling | `Run the DNA language model here: https://huggingface.co/kuleshov-group/caduceus-ph_seql...` |
| ml-model-track-overlap-q1 | Epigenomics | Retrieval | `Borzoi (Linder et al., doi:10.1038/s41588-024-02053-6) and Sei (Chen et al., doi:10.103...` |
| compute-gc-content-interval-q1 | Genomics | Routine Analysis | `Using the GRCh38.p13 human reference genome, retrieve the reference DNA sequence for ch...` |
| reverse-search-gwas-q1 | Population Genetics | Metadata Recovery | `Identify the PubMed ID of the study from which this summary statistics in reverse.searc...` |

Production of README.md:

    rmarkdown::render("README.Rmd", output_format = "github_document", output_file = "README.md", quiet = TRUE)
