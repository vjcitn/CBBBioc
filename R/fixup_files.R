#' get list of vectors of filenames when appropriate
#' @note original data is comma/space delimited
#' @export
fixup_files = function() {
  data("v1qs", package="CBBBioc")
  ans = strsplit(v1qs$file_path, ", ") |> (\(x)(lapply(x, function(z) gsub(" ", "", z))))()
  names(ans) = v1qs$question_id
  ans
}
