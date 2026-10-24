
# CBBBioc

Bioconductor interface to Genentech’s
[CompBioBench](https://github.com/genentech/compbiobench-runner) — a
benchmark of computational biology questions for evaluating LLM coding
agents (Claude Code, Codex, …).

`CBBBioc` catalogs the question set (`v1qs`), locates the input files
each question needs in cloud storage (`cbb_url()`), and stages
per-question agent workspaces (`cbb_setup_workspace()`) in the same
`workspace/` + `prompt.md` layout used by
[`compbiobench-runner`](https://github.com/genentech/compbiobench-runner).
See the package vignette for a worked example.

## Installation

``` r
# install.packages("remotes")
remotes::install_github("vjcitn/CBBBioc")
```

## Question catalog

`v1qs` currently holds 100 questions across these domains:

| Domain              | Freq |
|:--------------------|-----:|
| Epigenomics         |   20 |
| Genomics            |   20 |
| Machine Learning    |    7 |
| Population Genetics |   12 |
| Single-cell         |   21 |
| Spatial             |    2 |
| Structure           |    1 |
| Transcriptomics     |   17 |

73 of the 100 questions have one or more associated input files,
retrievable via `cbb_url()` and stageable with `cbb_setup_workspace()`.

### Browse the full catalog

GitHub’s markdown renderer strips the JavaScript an interactive table
needs, so the live, searchable/sortable version of this table lives in
the package website’s **Question catalog** article, alongside the
narrative context and references for the benchmark:

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
