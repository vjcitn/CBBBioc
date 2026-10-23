#!/usr/bin/env Rscript
# Regenerate docs/index.html: a standalone, searchable DT rendering of v1qs
# for GitHub Pages. Re-run this script (from the package root) whenever
# v1qs changes, and commit the resulting docs/index.html.

library(CBBBioc)
library(DT)
library(htmlwidgets)

data(v1qs)

tbl = v1qs[, c("question_id", "domain", "question_style", "curator_name",
               "skills_tested", "question", "internet_required",
               "gpu_preferred", "file_paths")]

widget = datatable(
  tbl,
  rownames = FALSE,
  filter = "top",
  extensions = "Buttons",
  caption = htmltools::tags$caption(
    style = "caption-side: top; text-align: left; font-size: 1.1em;",
    "CompBioBench v1qs question catalog (CBBBioc)"
  ),
  options = list(
    pageLength = 20,
    lengthMenu = c(10, 20, 50, 100),
    scrollX = TRUE,
    dom = "Blfrtip",
    buttons = c("copy", "csv"),
    columnDefs = list(list(width = "320px", targets = 5))
  )
)

out = file.path("docs", "index.html")
saveWidget(widget, out, selfcontained = TRUE, title = "CBBBioc question catalog")
message("Wrote ", out)
