# set up a self-contained folder for an agent to answer a v1qs question

set up a self-contained folder for an agent to answer a v1qs question

## Usage

``` r
cbb_setup_workspace(
  question_id,
  base_dir = tempdir(),
  timeout_minutes = 60,
  overwrite = FALSE,
  bfc = NULL
)
```

## Arguments

- question_id:

  character(1) value matched against \`v1qs\$question_id\`

- base_dir:

  path under which the question folder is created, default \`tempdir()\`

- timeout_minutes:

  numeric(1) time budget stated in the prompt, default 60

- overwrite:

  logical(1); if TRUE, remove and recreate an existing question folder

- bfc:

  a \`BiocFileCache\` instance; if NULL, \`cbb_filecache()\` is used

## Value

(invisibly) a list with elements \`question_dir\`, \`workspace_dir\`,
\`prompt_path\`, \`files\`, and \`prompt\`

## Note

mirrors the per-question \`workspace/\` + \`prompt.md\` layout produced
by Genentech's \`compbiobench-runner\` before it invokes an LLM CLI;
this function only stages the folder, it does not run any agent

## Examples

``` r
if (FALSE) { # \dontrun{
  ws = cbb_setup_workspace("bam-infer-read-length-q1")
  ws$workspace_dir
  cat(ws$prompt)
} # }
```
