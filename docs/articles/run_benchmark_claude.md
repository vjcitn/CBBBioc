# Running compbiobench-runner against Claude: a worked example

## Introduction

`CBBBioc` catalogs the CompBioBench question set (`v1qs`) and stages
per-question workspaces
([`vignette("setup_workspace")`](https://vjcitn.github.io/CBBBioc/articles/setup_workspace.md)),
but actually *running* an agent against a question – launching the LLM
CLI, isolating it in its own environment, collecting the answer and cost
– is the job of the companion Python tool,
[`compbiobench-runner`](https://github.com/genentech/compbiobench-runner),
which lives alongside this package as a sibling checkout (not an R
dependency).

This vignette is not executed as R code (the commands below are Python/
conda/shell, run outside R), but documents, with real captured output, a
first successful end-to-end run: `compbiobench-runner` driving the
*[claude](https://CRAN.R-project.org/package=claude)* – that is, the
Claude Code CLI – against the two sample questions bundled with the
runner (`test_benchmark.csv`).

## Prerequisites

`run_benchmark.py` clones a fresh `conda` environment per question for
reproducibility, so a working `conda` is required. **Use a
conda-forge-only installation
(e.g. [miniforge](https://github.com/conda-forge/miniforge)) – not
Homebrew’s conda, and not an Anaconda install that pulls from the
`defaults` channel.**

``` bash
export PATH="$HOME/miniforge3/bin:$PATH"
conda --version
conda config --show channels
#> channels:
#>   - conda-forge
```

A base environment named `compbio-benchmark`, built from
`compbiobench-runner`’s `environment.yml` (Python, `pysam`,
`pybedtools`, `biopython`, Node.js for the Codex CLI, …), must already
exist; it is cloned per question and the clone is removed afterwards
unless `--keep-envs` is given.

``` bash
conda env list | grep compbio-benchmark
#> compbio-benchmark      /Users/vincentcarey/miniforge3/envs/compbio-benchmark
```

The `claude` CLI must be installed, on `PATH`, and already authenticated
(`claude login`); `run_benchmark.py` checks this itself before starting:

``` bash
claude --version
#> 2.1.281 (Claude Code)
```

## Running the sample benchmark

The runner ships a two-question sanity-check file, `test_benchmark.csv`
(no associated input files – both are internet lookups):

``` bash
cat test_benchmark.csv
```

    question_id,question,curator_name,domain,date_added,difficulty,file_paths
    annotate-variant-gene-impact-q2072,"What is the clinical significance reported in the ClinVar database for the SPI1 variant represented by the HGVS notation NM_003120.3(SPI1):c.143-2A>C? Respond with only the correct cateogry. Answer in all lowercase.",Gokcen Eraslan,Variant Annotation,2025-09-03,1.0,
    variant-coordinate-lookup-1-q2821,"Retrieve the single base genomic position for the variant identifier rs200533370 on the GRCh38 reference assembly, and report it in chr#:position format (1-based, inclusive).",Laura Gunsalus,Variant Annotation,2025-09-03,1.0,

It is run with the Claude provider, serially (`-n 1`), at low reasoning
effort (sufficient for these two lookups):

``` bash
python run_benchmark.py run --llm claude --model-reasoning-effort low \
  -i test_benchmark.csv -n 1
```

Captured console output from this run:

    Checking claude CLI...
      'claude' at /opt/homebrew/bin/claude (v2.1.281 (Claude Code))
    Testing model 'claude-sonnet-4-5'...
      Model 'claude-sonnet-4-5' is accessible
      claude model_reasoning_effort: low
    Using mamba for env creation (faster!), conda for cloning
    Checking base conda environment...
      Base environment 'compbio-benchmark' ready (will clone for each question)
    ================================================================================
    LLM: claude | Model: claude-sonnet-4-5 | Base env: compbio-benchmark
    Questions: 2 | Parallel: 1 | Timeout: 120min
    ================================================================================
    [  1/2] annotate-variant-gene-impact-q | D:1.0 |    62s |  $0.1509 | [OK] pathogenic
    [  2/2] variant-coordinate-lookup-1-q2 | D:1.0 |    43s |  $0.0798 | [OK] chrX:47574285
    --------------------------------------------------------------------------------
    Done! OK: 2 | Errors: 0 | Total Cost: $0.2307

Both answers are correct: the SPI1 splice-acceptor variant is indeed
classified `pathogenic` in ClinVar, and rs200533370 maps to
`chrX:47574285` (GRCh38). Total cost for both questions: **\$0.2307**.

## Anatomy of the output

Each run creates `benchmark_runs/<llm>_<model>_<timestamp>/`, with
run-level metadata and a `questions/<question_id>/` folder per question:

``` bash
find benchmark_runs -maxdepth 3 -type d
```

    benchmark_runs/claude_claude-sonnet-4-5_20261027_062638
    benchmark_runs/claude_claude-sonnet-4-5_20261027_062638/questions
    benchmark_runs/claude_claude-sonnet-4-5_20261027_062638/questions/variant-coordinate-lookup-1-q2821
    benchmark_runs/claude_claude-sonnet-4-5_20261027_062638/questions/annotate-variant-gene-impact-q2072

`run_metadata.json` records the configuration for the whole run:

``` json
{
  "llm": "claude",
  "model": "claude-sonnet-4-5",
  "version": "2.1.281 (Claude Code)",
  "input_csv": "test_benchmark.csv",
  "parallel_jobs": 1,
  "timeout_minutes": 120,
  "base_env": "compbio-benchmark",
  "keep_envs": false,
  "model_reasoning_effort": "low",
  "timestamp": "20261027_062638",
  "total_questions": 2,
  "questions_to_run": 2
}
```

Each question folder holds `prompt.md` (exactly what was sent),
`result.json` (answer, tokens, cost), `trace.md` (human-readable
reasoning trace), and the raw CLI output. The prompt wraps the bare
question text in a standard instruction block and an output contract
requiring a single, unadorned line as the final answer:

    QUESTION: What is the clinical significance reported in the ClinVar database for the SPI1 variant represented by the HGVS notation NM_003120.3(SPI1):c.143-2A>C? Respond with only the correct cateogry. Answer in all lowercase.

    INSTRUCTIONS:
    - You have 120 minutes to complete this task
    - Do not read/access any other files outside the workspace.
    - Get any files or tools you need from the internet.
    - You are free to modify the current conda environment as needed.
    - Keep all scripts and intermediate data in the workspace only.

    OUTPUT CONTRACT (IMPORTANT):
    - Your final response will be graded by exact string match.
    - Return EXACTLY ONE LINE containing ONLY the final answer in the format required by the question.
    - Do NOT include any explanation, reasoning, labels, prefixes, markdown, code fences, citations, or extra whitespace lines.
    - Any extra text before or after the answer is incorrect.
    - Before sending your final response, verify it is exactly one line and nothing else.

`result.json`’s `usage` block is what the console summary’s cost column
is computed from:

``` json
{
  "input_tokens": 57,
  "output_tokens": 2842,
  "cache_creation_tokens": 10232,
  "cache_read_tokens": 155625,
  "models": [
    {
      "model": "claude-sonnet-4-5",
      "costUSD": 0.1508805
    }
  ]
}
```

## Example artifacts bundled with `CBBBioc`

The `compbiobench-runner` checkout used above is a sibling repo, not
part of this package, so its output isn’t guaranteed to persist. A
trimmed copy of this run’s artifacts (the input CSV,
`run_metadata.json`, and each question’s
`prompt.md`/`result.json`/`trace.md` – the raw CLI stdout/ stderr logs
are left out as not needed for illustration) ships under
`inst/benchmark_example/`, reachable via
[`system.file()`](https://rdrr.io/r/base/system.file.html), so the rest
of this section is genuinely executed, not pasted.

``` r

ex_dir = system.file("benchmark_example", package = "CBBBioc")
list.files(ex_dir, recursive = TRUE)
#> [1] "questions/annotate-variant-gene-impact-q2072/prompt.md"  
#> [2] "questions/annotate-variant-gene-impact-q2072/result.json"
#> [3] "questions/annotate-variant-gene-impact-q2072/trace.md"   
#> [4] "questions/variant-coordinate-lookup-1-q2821/prompt.md"   
#> [5] "questions/variant-coordinate-lookup-1-q2821/result.json" 
#> [6] "questions/variant-coordinate-lookup-1-q2821/trace.md"    
#> [7] "run_metadata.json"                                       
#> [8] "test_benchmark.csv"
```

``` r

qids = list.dirs(file.path(ex_dir, "questions"), full.names = FALSE,
                  recursive = FALSE)
do.call(rbind, lapply(qids, function(q) {
  res = jsonlite::fromJSON(file.path(ex_dir, "questions", q, "result.json"))
  data.frame(
    question_id = q,
    answer = res$output$answer,
    elapsed_s = res$execution$elapsed_time,
    cost_usd = res$usage$models$costUSD
  )
}))
#>                          question_id        answer elapsed_s  cost_usd
#> 1 annotate-variant-gene-impact-q2072    pathogenic     61.68 0.1508805
#> 2  variant-coordinate-lookup-1-q2821 chrX:47574285     43.44 0.0797976
```

Cost is derived from token usage, which `result.json` also records in
full – input/output tokens actually billed, plus how much of the context
was served from (or written to) Claude’s prompt cache:

``` r

do.call(rbind, lapply(qids, function(q) {
  u = jsonlite::fromJSON(file.path(ex_dir, "questions", q, "result.json"))$usage
  data.frame(
    question_id = q,
    input_tokens = u$input_tokens,
    output_tokens = u$output_tokens,
    cache_creation_tokens = u$cache_creation_tokens,
    cache_read_tokens = u$cache_read_tokens,
    thinking_tokens = u$thinking_tokens
  )
}))
#>                          question_id input_tokens output_tokens
#> 1 annotate-variant-gene-impact-q2072           57          2842
#> 2  variant-coordinate-lookup-1-q2821           33          1121
#>   cache_creation_tokens cache_read_tokens thinking_tokens
#> 1                 10232            155625               0
#> 2                  6431             80992               0
```

## Next: running against `v1qs`

This test used the runner’s own two-question file, which needs no input
files. Scaling this up to real `v1qs` questions means building a
`benchmark.csv` in the schema `run_benchmark.py` expects
(`question_id, question, file_paths, ...`), where `file_paths` must be
**absolute local paths** – the runner copies them into each question’s
workspace itself, it does not fetch from cloud storage. For questions
that reference files, that means first staging them locally – exactly
what
[`cbb_fetch_files()`](https://vjcitn.github.io/CBBBioc/reference/cbb_fetch_files.md)
/
[`cbb_filecache()`](https://vjcitn.github.io/CBBBioc/reference/cbb_filecache.md)
already do (see
[`vignette("setup_workspace")`](https://vjcitn.github.io/CBBBioc/articles/setup_workspace.md))
– and writing the resulting local paths into the CSV’s `file_paths`
column. That worked example is left for a follow-up vignette.

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
#> [1] BiocStyle_2.41.0
#> 
#> loaded via a namespace (and not attached):
#>  [1] digest_0.6.39       desc_1.4.3          R6_2.6.1           
#>  [4] bookdown_0.48       fastmap_1.2.0       xfun_0.61          
#>  [7] cachem_1.1.0        knitr_1.52          htmltools_0.5.9    
#> [10] rmarkdown_2.32      lifecycle_1.0.5     cli_3.6.6          
#> [13] sass_0.4.10         pkgdown_2.2.1       textshaping_1.0.5  
#> [16] jquerylib_0.1.4     systemfonts_1.3.2   compiler_4.6.1     
#> [19] tools_4.6.1         ragg_1.5.2          bslib_0.12.0       
#> [22] evaluate_1.0.5      yaml_2.3.12         BiocManager_1.30.27
#> [25] otel_0.2.0          jsonlite_2.0.0      rlang_1.3.0        
#> [28] fs_2.1.0            htmlwidgets_1.6.4
```
