# write a human-readable prompt.md describing a staged question

write a human-readable prompt.md describing a staged question

## Usage

``` r
.cbb_write_prompt_md(
  prompt_path,
  question_id,
  domain,
  question_style,
  files,
  prompt
)
```

## Arguments

- prompt_path:

  path to write

- question_id:

  character(1) question identifier

- domain:

  value to report (may be NA)

- question_style:

  value to report (may be NA)

- files:

  character vector of workspace-relative file names

- prompt:

  character(1) full prompt text, as produced by \`cbb_build_prompt()\`

## Value

(invisibly) \`prompt_path\`
