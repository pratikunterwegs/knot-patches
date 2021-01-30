#!/bin/bash

# style rmd
Rscript --vanilla --slave -e 'styler::style_dir(".", filetype = "Rmd", recursive = FALSE)'

Rscript --slave -e 'bookdown::render_book("index.rmd")'

Rscript --slave -e 'bookdown::render_book("index.rmd", "bookdown::pdf_document2")'

# to render source files
Rscript --slave -e 'lapply(list.files(pattern = "\\d{2}\\w+.Rmd"), function(x) knitr::purl(x, output = sprintf("R/%s", gsub(".{4}$", ".R", x))))'
