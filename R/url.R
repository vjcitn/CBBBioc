#' form the url for retrieva of a CompBioBench datasets
#' @param x name of resource
#' @note must be found in `cbb_data$name`
#' @export
cbb_url = function(x) sprintf("https://mghp.osn.xsede.org/bir190004-bucket01/BiocCBBData/%s", x)
