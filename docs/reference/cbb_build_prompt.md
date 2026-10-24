# build the agent-facing prompt text for a question

build the agent-facing prompt text for a question

## Usage

``` r
cbb_build_prompt(question, files = character(0), timeout_minutes = 60)
```

## Arguments

- question:

  character(1) question text

- files:

  character vector of workspace-relative file names available to the
  agent

- timeout_minutes:

  numeric(1) time budget to state in the prompt

## Value

character(1) prompt text

## Note

mirrors the prompt format produced by \`generate_prompt()\` in
Genentech's \`compbiobench-runner\` (\`run_benchmark.py\`), so prompts
staged here are comparable to those used by that runner
