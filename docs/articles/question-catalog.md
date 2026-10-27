# The CompBioBench question catalog

## Background

[CompBioBench](https://github.com/genentech/compbiobench-runner) is a
benchmark, developed at Genentech. It supports evaluation of LLM coding
agents (Claude Code, Codex, …) on computational biology tasks.

``` r

library(CBBBioc)
library(DT)
data(v1qs)
```

The CBBBioc package includes a snapshot of questions and their
classification into scientific subcategories of computational biology.
Each question combines a domain with a question style. We tabulate
domain/style combinations in the snapshot:

``` r

knitr::kable(as.data.frame.matrix(
  table(Domain = v1qs$domain, Style = v1qs$question_style)
))
```

|  | Metadata Recovery | Retrieval | Routine Analysis | Synthetic/Augmented Data | Tooling |
|:---|---:|---:|---:|---:|---:|
| Epigenomics | 8 | 4 | 4 | 3 | 1 |
| Genomics | 1 | 8 | 7 | 4 | 0 |
| Machine Learning | 0 | 0 | 0 | 0 | 7 |
| Population Genetics | 8 | 3 | 0 | 1 | 0 |
| Single-cell | 8 | 1 | 5 | 7 | 0 |
| Spatial | 0 | 0 | 0 | 2 | 0 |
| Structure | 0 | 0 | 0 | 1 | 0 |
| Transcriptomics | 2 | 1 | 6 | 8 | 0 |

A question may reference one or more data files that the agent can
retrieve from cloud storage in order to work on the solution. A python
module (`run_benchmark.py`) from Genentech’s `compbiobench-runner`
[repository](https://github.com/genentech/compbiobench-runner) drives an
agent through each question in an isolated conda environment and records
the agent’s answer, reasoning trace, and token/cost usage.

`CBBBioc` packages the question metadata for each benchmark as a data
element in `v1qs`. The package also provides
[`cbb_url()`](https://vjcitn.github.io/CBBBioc/reference/cbb_url.md) to
resolve each referenced file to its location in cloud storage, and
provides
[`cbb_setup_workspace()`](https://vjcitn.github.io/CBBBioc/reference/cbb_setup_workspace.md)
to stage a `workspace/` + `prompt.md` folder for a question exactly as
`compbiobench-runner` would. so that the question set can be explored,
and individual questions worked, from R. See the
[`vignette("setup_workspace")`](https://vjcitn.github.io/CBBBioc/articles/setup_workspace.md)
vignette.

This vignette is a narrative, browsable tour of the question catalog
itself.

## The question data

Each row of `v1qs` is one benchmark question:

``` r

colnames(v1qs)
#> [1] "question_id"       "curator_name"      "domain"           
#> [4] "question_style"    "skills_tested"     "question"         
#> [7] "internet_required" "gpu_preferred"     "file_paths"
```

- **question_id** – a short, stable identifier (e.g. ensembl-grab-q1)
- **domain** / **question_style** / **skills_tested** – how the question
  is categorized (domain area, task shape, skills exercised)
- **question** – the task as posed to the agent
- **file_paths** – comma-separated input file name(s), if any; resolved
  via
  [`cbb_url()`](https://vjcitn.github.io/CBBBioc/reference/cbb_url.md)
  and fetched into a workspace by
  [`cbb_setup_workspace()`](https://vjcitn.github.io/CBBBioc/reference/cbb_setup_workspace.md)
- **internet_required** / **gpu_preferred** – hints about what the
  answering agent may need access to

## Coverage by domain

``` r

dom_summary = do.call(rbind, lapply(sort(unique(v1qs$domain)), function(d) {
  sub = v1qs[v1qs$domain == d, ]
  exts = unique(unlist(lapply(
    strsplit(sub$file_paths[sub$file_paths != ""], ", "),
    function(z) tools::file_ext(gsub(" ", "", z))
  )))
  exts = exts[exts != ""]
  ex_q = sub$question[1]
  data.frame(
    Domain = d,
    Freq = nrow(sub),
    `File types used` = if (length(exts)) paste(sort(exts), collapse = ", ") else "(none)",
    `Example question` = ex_q,
    check.names = FALSE
  )
}))
knitr::kable(dom_summary, row.names = FALSE)
```

| Domain | Freq | File types used | Example question |
|:---|---:|:---|:---|
| Epigenomics | 20 | bigWig, csv, fasta, gz, tar | Consider chr11:124,738,681-124,738,772 (hg38). What is the likely purpose of this region? Choose only one. A. Active enhancer, Liver B. Active enhancer, Brain frontal lobe C. Active enhancer, ESC D. Active transcription, ubiquitous E. TSS poised or flanking, ubiquitous F. Polycomb repression, ubiquitous. Respond with a single letter. |
| Genomics | 20 | bam, fa, fna, gz | Convert all of the following to Ensembl gene IDs. Provide the ID without the Ensembl version (e.g., ENSGXXXXXXXXXXXX not ENSGXXXXXXXXXXXX.XX). Respond with semi-colon separated values, no spaces. Inputs: 1. NM_001276266.2 2. TERB2 3. ENST00000267814 4. chr15:45167214-45187966 (hg38) 5. GeneID:9153 6. NP_922946.1 7. MIM:617658 8. BEN domain containing 5, transcript variant 6. |
| Machine Learning | 7 | pdf, tsv | Run the DNA language model here: <https://huggingface.co/kuleshov-group/caduceus-ph_seqlen-131k_d_model-256_n_layer-16> on the 1000 bp long DNA sequence at hg38 chr12:7792299-7793299. Specifically, mask each base one at a time, keeping all others unmasked, and compute the per position base 2 entropy of the predictions. Return the substring corresponding to the longest run with \<0.5 entropy. |
| Population Genetics | 12 | gz | Identify the PubMed ID of the study from which this summary statistics in reverse.search.gwas.q1.tsv.gz are derived. Print only the PMID, e.g. 31510655. |
| Single-cell | 21 | bam, gz, h5ad, rds, sizes | differential.composition.q1.1.mtx.gz and differential.composition.q1.2.mtx.gz contain raw scRNA counts matrices derived from retinal samples of two individuals (one per file, each column is a unique barcode that passes QC). differential.composition.q1.genes.txt.gz is the list of common genes. One of the cell types is severely depleted in one of the two individuals. What is this cell type? Return only the name of the depleted cell type from this list: astrocyte, microglial cell, RPE cell, cone cell, rod cell, horizontal cell, bipolar cell, RGC, T cells, macrophage, Schwann cell, Pericyte, B cell, fibroblast, endothelial cell, muller glia cell. |
| Spatial | 2 | gz | You are given a set of single cell transcriptomic data and Visium spatial transcriptomic data (spatial.sim.tar.gz). The single cell counts matrix is found at spatial_q_sc_counts.csv, and accompanying cell type metadata is found at spatial_q_sc_metadata.csv. Spatial count data is found at spatial_q_matrix.mtx.gz, gene counts are found at spatial_q_features.tsv.gz, and are found at spot barcodes spatial_q_barcodes.tsv.gz. Finally scale factors are found at spatial_q_scalefactors_json.json, high and low resolution tissue images are found at spatial_q_tissue_hires_image.png and patial_q_tissue_hires_image.png respectively, and tissue positions are found at spatial_q_tissue_positions.csv. The spot-based data is comprised entirely of cell types found in the single cell data. Can you tell me what cell type or cell types, if any, are biased towards being in closer spatial proximity to spots containing Tumor_Core? If none, please return “None”. Please list these separated by commas in alphabetical order. Expected answer format: Endothelial,Macrophage. |
| Structure | 1 | pdb | Consider the PDB protein in the file protein.shape.q1.pdb. Which of the following uppercase letters does it resemble most closely: B, D, F, H, J, L, N, P, R, T, V, X, Z? Consider all possible projections and pick the best fit. |
| Transcriptomics | 17 | bam, fq, gz, tsv, txt | I have a bulk human RNA-seq fastq file cryptic.exon.q1.fq.gz. There is exactly one highly expressed coding gene that has a cryptic exon in it formed by two novel junctions. Report the HGNC gene symbol (uppercase) for that gene. |

``` r

has_files = sum(v1qs$file_paths != "")
```

100 questions are cataloged in total; 73 of them (73%) have one or more
associated input files.

## Browsing the full catalog

The table below is interactive: use the column filters to narrow by
domain or question style, search across question text, and sort columns.

## From browsing to staging

Once a question of interest is identified – say ensembl-grab-q1 –
[`cbb_setup_workspace()`](https://vjcitn.github.io/CBBBioc/reference/cbb_setup_workspace.md)
creates a folder an agent (or a person) can work from directly:

``` r

ws = cbb_setup_workspace(v1qs$question_id[1])
ws$workspace_dir  # cd here
cat(ws$prompt)    # what to ask the agent
```

See
[`vignette("setup_workspace")`](https://vjcitn.github.io/CBBBioc/articles/setup_workspace.md)
for a fuller walk-through, including the
*[BiocFileCache](https://bioconductor.org/packages/3.24/BiocFileCache)*-backed
download caching used when a question’s files need to be fetched from
cloud storage.

## References

- CompBioBench runner:
  <https://github.com/genentech/compbiobench-runner>
- `CBBBioc` source: <https://github.com/vjcitn/CBBBioc>

## Session info

``` r

sessionInfo()
#> R version 4.6.1 (2026-06-24)
#> Platform: aarch64-apple-darwin23
#> Running under: macOS Golden Gate 27.0.1
#> 
#> Matrix products: default
#> BLAS:   /System/Library/Frameworks/Accelerate.framework/Versions/A/Frameworks/vecLib.framework/Versions/A/libBLAS.dylib 
#> LAPACK: /Library/Frameworks/R.framework/Versions/4.6/Resources/lib/libRlapack.dylib;  LAPACK version 3.12.1
#> 
#> locale:
#> [1] en_US.UTF-8/en_US.UTF-8/en_US.UTF-8/C/en_US.UTF-8/en_US.UTF-8
#> 
#> time zone: America/New_York
#> tzcode source: internal
#> 
#> attached base packages:
#> [1] stats     graphics  grDevices utils     datasets  methods   base     
#> 
#> other attached packages:
#> [1] DT_0.34.0        CBBBioc_0.0.2    BiocStyle_2.41.0
#> 
#> loaded via a namespace (and not attached):
#>  [1] cli_3.6.6           knitr_1.52          rlang_1.3.0        
#>  [4] xfun_0.61           otel_0.2.0          textshaping_1.0.5  
#>  [7] jsonlite_2.0.0      htmltools_0.5.9     ragg_1.5.2         
#> [10] sass_0.4.10         rmarkdown_2.32      crosstalk_1.2.2    
#> [13] evaluate_1.0.5      jquerylib_0.1.4     fastmap_1.2.0      
#> [16] yaml_2.3.12         lifecycle_1.0.5     bookdown_0.48      
#> [19] BiocManager_1.30.27 compiler_4.6.1      fs_2.1.0           
#> [22] htmlwidgets_1.6.4   systemfonts_1.3.2   digest_0.6.39      
#> [25] R6_2.6.1            magrittr_2.0.5      bslib_0.12.0       
#> [28] tools_4.6.1         pkgdown_2.2.1       cachem_1.1.0       
#> [31] desc_1.4.3
```
