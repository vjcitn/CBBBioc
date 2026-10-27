# Staging agent workspaces for CompBioBench questions

``` r

# wrap a multi-line prompt line-by-line so it reads without horizontal scrolling
wrap_prompt = function(prompt, width = 80) {
  lines = strsplit(prompt, "\n")[[1]]
  unlist(lapply(lines, function(l) if (nzchar(l)) strwrap(l, width = width) else ""))
}
```

## Introduction

Genentech’s `compbiobench-runner` benchmarks LLM CLI agents (Claude
Code, Codex, …) on computational biology questions. For each question it
builds a per-question folder containing a `workspace/` directory
(holding any input files the question references) and a `prompt.md`
describing the task, then launches an agent inside that folder.

`CBBBioc` catalogs the same question set, in the `v1qs` data element,
and provides
[`cbb_url()`](https://vjcitn.github.io/CBBBioc/reference/cbb_url.md) to
locate each input file in cloud storage. This vignette demonstrates
[`cbb_setup_workspace()`](https://vjcitn.github.io/CBBBioc/reference/cbb_setup_workspace.md),
which stages a folder for a single `v1qs` question in the same shape
that `compbiobench-runner` uses, so that an agent (or a person) can be
pointed at `workspace_dir` and given `prompt` to work from. Downloads
are cached with
*[BiocFileCache](https://bioconductor.org/packages/3.24/BiocFileCache)*
so that re-staging the same question does not re-fetch files that are
already local.

``` r

library(CBBBioc)
```

We check for network access once, since fetching question files requires
reaching the cloud bucket behind
[`cbb_url()`](https://vjcitn.github.io/CBBBioc/reference/cbb_url.md).

``` r

net_ok = !inherits(
  try(suppressWarnings(close(url(cbb_url("mt.sorted.bam"), open = "rb"))), silent = TRUE),
  "try-error"
)
net_ok
#> [1] TRUE
```

## Case 1: a question with no associated files

Many questions (e.g. identifier lookups) need no input files at all.
[`cbb_setup_workspace()`](https://vjcitn.github.io/CBBBioc/reference/cbb_setup_workspace.md)
still creates the folder and the prompt, just with an empty
`workspace/`.

``` r

ws1 = cbb_setup_workspace("ensembl-grab-q1", base_dir = tempdir(), overwrite = TRUE)
ws1$workspace_dir
#> [1] "/var/folders/yw/gfhgh7k565v9w83x_k764wbc0000gp/T//Rtmprdl7FZ/ensembl-grab-q1/workspace"
ws1$files
#> character(0)
list.files(ws1$workspace_dir)
#> character(0)
cat(wrap_prompt(ws1$prompt), sep = "\n")
#> QUESTION: Convert all of the following to Ensembl gene IDs. Provide the ID
#> without the Ensembl version (e.g., ENSGXXXXXXXXXXXX not ENSGXXXXXXXXXXXX.XX).
#> Respond with semi-colon separated values, no spaces. Inputs: 1. NM_001276266.2
#> 2. TERB2 3. ENST00000267814 4. chr15:45167214-45187966 (hg38) 5. GeneID:9153 6.
#> NP_922946.1 7. MIM:617658 8. BEN domain containing 5, transcript variant 6.
#> 
#> INSTRUCTIONS:
#> - You have 60 minutes to complete this task
#> - Do not read/access any other files outside the workspace.
#> - Get any files or tools you need from the internet.
#> - You are free to modify the current conda environment as needed.
#> - Keep all scripts and intermediate data in the workspace only.
#> 
#> OUTPUT CONTRACT (IMPORTANT):
#> - Your final response will be graded by exact string match.
#> - Return EXACTLY ONE LINE containing **ONLY** the final answer in the format
#> required by the question.
#> - Do NOT include any explanation, reasoning, labels, prefixes, markdown, code
#> fences, citations, or extra whitespace lines.
#> - Any extra text before or after the answer is incorrect.
#> - Before sending your final response, verify it is exactly one line and nothing
#> else.
```

## Case 2: a question with a single file, and caching behavior

`bam-infer-read-length-q1` references one BAM file. The first call to
[`cbb_setup_workspace()`](https://vjcitn.github.io/CBBBioc/reference/cbb_setup_workspace.md)
downloads it through
[`cbb_filecache()`](https://vjcitn.github.io/CBBBioc/reference/cbb_filecache.md);
a second call for the same question reuses the cached copy rather than
re-downloading, which we can see as a drop in elapsed time.

``` r

t0 = system.time(
  ws2 <- cbb_setup_workspace("bam-infer-read-length-q1", base_dir = tempdir(), overwrite = TRUE)
)
ws2$files
#> [1] "mt.sorted.bam"
file.size(file.path(ws2$workspace_dir, ws2$files))
#> [1] 876871
t0[["elapsed"]]
#> [1] 0.07
```

``` r

t1 = system.time(
  ws2b <- cbb_setup_workspace("bam-infer-read-length-q1", base_dir = tempdir(), overwrite = TRUE)
)
t1[["elapsed"]]
#> [1] 0.039
```

The second call is substantially faster because `BiocFileCache` resolved
the file from its local cache instead of downloading it again.

## Case 3: a question with multiple files

`differential-composition-q1` references three files (two count matrices
and a gene list). All are fetched into the same workspace, and `FILES:`
in the prompt lists all of them.

``` r

ws3 = cbb_setup_workspace("differential-composition-q1", base_dir = tempdir(), overwrite = TRUE)
ws3$files
#> [1] "differential.composition.q1.1.mtx.gz"    
#> [2] "differential.composition.q1.2.mtx.gz"    
#> [3] "differential.composition.q1.genes.txt.gz"
list.files(ws3$workspace_dir)
#> [1] "differential.composition.q1.1.mtx.gz"    
#> [2] "differential.composition.q1.2.mtx.gz"    
#> [3] "differential.composition.q1.genes.txt.gz"
cat(wrap_prompt(ws3$prompt), sep = "\n")
#> QUESTION: differential.composition.q1.1.mtx.gz and
#> differential.composition.q1.2.mtx.gz contain raw scRNA counts matrices derived
#> from retinal samples of two individuals (one per file, each column is a unique
#> barcode that passes QC). differential.composition.q1.genes.txt.gz is the list
#> of common genes. One of the cell types is severely depleted in one of the two
#> individuals. What is this cell type? Return only the name of the depleted cell
#> type from this list: astrocyte, microglial cell, RPE cell, cone cell, rod cell,
#> horizontal cell, bipolar cell, RGC, T cells, macrophage, Schwann cell,
#> Pericyte, B cell, fibroblast, endothelial cell, muller glia cell.
#> 
#> FILES: differential.composition.q1.1.mtx.gz,
#> differential.composition.q1.2.mtx.gz, differential.composition.q1.genes.txt.gz
#> 
#> Note: All files are located in your current working directory (workspace).
#> 
#> INSTRUCTIONS:
#> - You have 60 minutes to complete this task
#> - Do not read/access any other files outside the workspace.
#> - Get any files or tools you need from the internet.
#> - You are free to modify the current conda environment as needed.
#> - Keep all scripts and intermediate data in the workspace only.
#> 
#> OUTPUT CONTRACT (IMPORTANT):
#> - Your final response will be graded by exact string match.
#> - Return EXACTLY ONE LINE containing **ONLY** the final answer in the format
#> required by the question.
#> - Do NOT include any explanation, reasoning, labels, prefixes, markdown, code
#> fences, citations, or extra whitespace lines.
#> - Any extra text before or after the answer is incorrect.
#> - Before sending your final response, verify it is exactly one line and nothing
#> else.
```

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
#> [1] CBBBioc_0.0.1    BiocStyle_2.41.0
#> 
#> loaded via a namespace (and not attached):
#>  [1] bit_4.6.0           jsonlite_2.0.0      dplyr_1.2.1        
#>  [4] compiler_4.6.1      BiocManager_1.30.27 filelock_1.0.3     
#>  [7] tidyselect_1.2.1    blob_1.3.0          jquerylib_0.1.4    
#> [10] systemfonts_1.3.2   textshaping_1.0.5   yaml_2.3.12        
#> [13] fastmap_1.2.0       R6_2.6.1            generics_0.1.4     
#> [16] curl_8.1.0          httr2_1.3.0         knitr_1.52         
#> [19] htmlwidgets_1.6.4   tibble_3.3.1        bookdown_0.48      
#> [22] desc_1.4.3          DBI_1.3.0           pillar_1.11.1      
#> [25] bslib_0.12.0        rlang_1.3.0         cachem_1.1.0       
#> [28] xfun_0.61           fs_2.1.0            sass_0.4.10        
#> [31] bit64_4.8.6         otel_0.2.0          RSQLite_3.53.3     
#> [34] memoise_2.0.1       cli_3.6.6           withr_3.0.3        
#> [37] pkgdown_2.2.1       magrittr_2.0.5      digest_0.6.39      
#> [40] dbplyr_2.6.0        lifecycle_1.0.5     BiocFileCache_3.3.0
#> [43] vctrs_0.7.3         evaluate_1.0.5      glue_1.8.1         
#> [46] ragg_1.5.2          purrr_1.2.2         rmarkdown_2.32     
#> [49] pkgconfig_2.0.3     tools_4.6.1         htmltools_0.5.9
```
