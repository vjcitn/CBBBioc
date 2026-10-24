# fetch the files associated with a question into a destination directory

fetch the files associated with a question into a destination directory

## Usage

``` r
cbb_fetch_files(question_id, dest_dir, bfc = NULL)
```

## Arguments

- question_id:

  character(1) value matched against \`v1qs\$question_id\`

- dest_dir:

  path to directory where files should be placed

- bfc:

  a \`BiocFileCache\` instance; if NULL, \`cbb_filecache()\` is used

## Value

character vector of file names written into \`dest_dir\` (empty if the
question has no associated files)

## Note

downloads go through \`cbb_filecache()\`, so a file already cached
locally is not re-downloaded; it is just copied from the cache into
\`dest_dir\`
