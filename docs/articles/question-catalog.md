# The CompBioBench question catalog

## Background

[CompBioBench](https://github.com/genentech/compbiobench-runner) is a
benchmark, developed at Genentech, for evaluating LLM coding agents
(Claude Code, Codex, …) on computational biology tasks. Each benchmark
question poses a concrete bioinformatics problem – identifier
translation, metadata recovery from a sequencing file, interpreting a
genomic locus, reproducing a published analysis, and so on – and may
reference one or more data files that the agent needs in order to
answer. `compbiobench-runner`’s `run_benchmark.py` drives an agent
through each question in an isolated conda environment and records the
agent’s answer, reasoning trace, and token/cost usage.

`CBBBioc` packages the question metadata for that benchmark as the data
element `v1qs`, provides
[`cbb_url()`](https://vjcitn.github.io/CBBBioc/reference/cbb_url.md) to
resolve each referenced file to its location in cloud storage, and
provides
[`cbb_setup_workspace()`](https://vjcitn.github.io/CBBBioc/reference/cbb_setup_workspace.md)
to stage a `workspace/` + `prompt.md` folder for a question exactly as
`compbiobench-runner` would, so that the question set can be explored,
and individual questions worked, from R. See the
[`vignette("setup_workspace")`](https://vjcitn.github.io/CBBBioc/articles/setup_workspace.md)
vignette for that workflow end to end.

This vignette is a narrative, browsable tour of the question catalog
itself.

``` r

library(CBBBioc)
library(DT)
data(v1qs)
```

## What’s in a question

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
  # wrap (not truncate) the example question, and join with <br/> so the
  # table cell wraps onto multiple lines instead of forcing horizontal scroll
  ex_q = paste(strwrap(sub$question[1], width = 50), collapse = "<br/>")
  data.frame(
    Domain = d,
    Freq = nrow(sub),
    `File types used` = if (length(exts)) paste(sort(exts), collapse = ", ") else "(none)",
    `Example question` = ex_q,
    check.names = FALSE
  )
}))
knitr::kable(dom_summary, row.names = FALSE, escape = FALSE)
```

[TABLE]

``` r

has_files = sum(v1qs$file_paths != "")
```

100 questions are cataloged in total; 73 of them (73%) have one or more
associated input files.

## Browsing the full catalog

The table below is interactive: use the column filters to narrow by
domain or question style, search across question text, and sort columns.
(If you are reading this on CRAN/Bioconductor’s static vignette viewer
rather than the *[pkgdown](https://CRAN.R-project.org/package=pkgdown)*
site, the widget still renders, but try the [pkgdown
site](https://vjcitn.github.io/CBBBioc/) for the full-width view.)

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
#> [1] DT_0.34.0        CBBBioc_0.0.1    BiocStyle_2.41.0
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
