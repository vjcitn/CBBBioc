# get (creating if needed) the BiocFileCache used for CompBioBench downloads

get (creating if needed) the BiocFileCache used for CompBioBench
downloads

## Usage

``` r
cbb_filecache(cache_dir = NULL)
```

## Arguments

- cache_dir:

  path to cache directory, default from
  \`BiocFileCache::getBFCOption("CACHE")\`

## Value

a \`BiocFileCache\` instance

## Note

downloads are cached by URL, so repeated calls for the same file reuse
the local copy
